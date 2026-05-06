import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/common/cubits/app/app_lifecycle_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart'
    as global_auth;
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/network/network_utils/connection_checker.dart';
import 'package:oshmobile/features/startup/domain/contracts/startup_auth_bootstrapper.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_decision.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';
import 'package:oshmobile/features/startup/domain/repositories/startup_client_policy_repository.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:oshmobile/features/startup/presentation/cubit/startup_state.dart';
import 'package:oshmobile/features/startup/presentation/widgets/startup_gate.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  setUp(() {
    OshAnalytics.debugSetBackend(const _NoopAnalyticsBackend());
  });

  tearDown(() {
    OshAnalytics.debugResetBackend();
  });

  testWidgets('renders key startup stages', (WidgetTester tester) async {
    final startupCubit = _TestStartupCubit();
    final authCubit = _TestGlobalAuthCubit();

    await _pumpStartupGate(
      tester,
      startupCubit: startupCubit,
      authCubit: authCubit,
    );

    expect(find.text('Checking internet connection...'), findsOneWidget);

    startupCubit.emitForTest(
      const StartupState(stage: StartupStage.noInternet),
    );
    await tester.pump();
    expect(find.text('No internet connection'), findsOneWidget);

    startupCubit.emitForTest(
      const StartupState(stage: StartupStage.ready),
    );
    await tester.pump();
    expect(find.text('sign-in'), findsOneWidget);

    await startupCubit.close();
    await authCubit.close();
  });

  testWidgets('ready + hard update renders blocking page',
      (WidgetTester tester) async {
    final startupCubit = _TestStartupCubit()
      ..emitForTest(
        const StartupState(
          stage: StartupStage.ready,
          hardUpdateRequired: true,
        ),
      );
    final authCubit = _TestGlobalAuthCubit();

    await _pumpStartupGate(
      tester,
      startupCubit: startupCubit,
      authCubit: authCubit,
    );

    expect(find.text('Update app to continue'), findsOneWidget);
    expect(find.text('sign-in'), findsNothing);

    await startupCubit.close();
    await authCubit.close();
  });

  testWidgets('hard update transition shows blocking flow above current route',
      (WidgetTester tester) async {
    final startupCubit = _TestStartupCubit()
      ..emitForTest(const StartupState(stage: StartupStage.ready));
    final authCubit = _TestGlobalAuthCubit();

    await _pumpStartupGate(
      tester,
      startupCubit: startupCubit,
      authCubit: authCubit,
    );

    final navigator = Navigator.of(tester.element(find.text('sign-in')));
    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('details')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('details'), findsOneWidget);

    startupCubit.emitForTest(
      const StartupState(
        stage: StartupStage.ready,
        hardUpdateRequired: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update app to continue'), findsOneWidget);
    expect(find.text('details'), findsNothing);

    await startupCubit.close();
    await authCubit.close();
  });

  testWidgets('ready state routes through GlobalAuthCubit',
      (WidgetTester tester) async {
    final startupCubit = _TestStartupCubit()
      ..emitForTest(const StartupState(stage: StartupStage.ready));
    final authCubit = _TestGlobalAuthCubit();

    await _pumpStartupGate(
      tester,
      startupCubit: startupCubit,
      authCubit: authCubit,
    );

    expect(find.text('sign-in'), findsOneWidget);
    expect(find.text('home'), findsNothing);

    authCubit.emitForTest(const global_auth.AuthAuthenticated(1));
    await tester.pump();

    expect(find.text('home'), findsOneWidget);
    expect(find.text('sign-in'), findsNothing);

    await startupCubit.close();
    await authCubit.close();
  });
}

Future<void> _pumpStartupGate(
  WidgetTester tester, {
  required StartupCubit startupCubit,
  required global_auth.GlobalAuthCubit authCubit,
}) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AppLifecycleCubit>(create: (_) => AppLifecycleCubit()),
        BlocProvider<StartupCubit>.value(value: startupCubit),
        BlocProvider<global_auth.GlobalAuthCubit>.value(value: authCubit),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const StartupGate(
          authenticatedBuilder: _homeBuilder,
          unauthenticatedBuilder: _signInBuilder,
        ),
      ),
    ),
  );
}

Widget _homeBuilder(BuildContext context) => const Text('home');

Widget _signInBuilder(BuildContext context) => const Text('sign-in');

class _TestStartupCubit extends StartupCubit {
  _TestStartupCubit()
      : super(
          connectionChecker: _FakeInternetConnectionChecker(),
          authBootstrapper: _FakeStartupAuthBootstrapper(),
          clientPolicyRepository: _FakeStartupClientPolicyRepository(),
        );

  void emitForTest(StartupState state) {
    emit(state);
  }
}

class _TestGlobalAuthCubit extends global_auth.GlobalAuthCubit {
  _TestGlobalAuthCubit()
      : super(
          authService: AuthService.create(),
          mobileService: MobileV1Service.create(),
          sessionStorage: SessionStorage(storage: FlutterSecureStorage()),
          keycloakWrapper: KeycloakWrapper(),
        );

  void emitForTest(global_auth.GlobalAuthState state) {
    emit(state);
  }
}

class _FakeInternetConnectionChecker implements InternetConnectionChecker {
  @override
  Future<bool> get isConnected async => true;
}

class _FakeStartupAuthBootstrapper implements StartupAuthBootstrapper {
  @override
  Future<bool> checkAuthStatus() async => true;
}

class _FakeStartupClientPolicyRepository
    implements StartupClientPolicyRepository {
  @override
  Future<MobileClientPolicyDecision> checkPolicy() async {
    return const MobileClientPolicyDecision(
      status: MobileClientPolicyStatus.allow,
    );
  }

  @override
  Future<void> suppressRecommendPrompt({required int policyVersion}) async {}
}

class _NoopAnalyticsBackend implements AnalyticsBackend {
  const _NoopAnalyticsBackend();

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}
