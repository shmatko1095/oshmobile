import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/common/cubits/app/app_theme_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata.dart';
import 'package:oshmobile/core/network/app_client/app_client_metadata_provider.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/core/theme/theme_mode_storage.dart';
import 'package:oshmobile/features/account_settings/domain/usecases/request_my_account_deletion.dart';
import 'package:oshmobile/features/account_settings/presentation/cubit/account_settings_cubit.dart';
import 'package:oshmobile/features/account_settings/presentation/pages/account_deletion_request_page.dart';
import 'package:oshmobile/features/account_settings/presentation/pages/account_profile_page.dart';
import 'package:oshmobile/features/account_settings/presentation/pages/account_settings_page.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_decision.dart';
import 'package:oshmobile/features/startup/domain/models/mobile_client_policy_status.dart';
import 'package:oshmobile/features/startup/domain/repositories/startup_client_policy_repository.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

void main() {
  late _FakeStartupClientPolicyRepository clientPolicyRepository;
  late _FakeAppClientMetadataProvider metadataProvider;
  late _FakeRequestMyAccountDeletion requestMyAccountDeletion;
  late AppThemeCubit appThemeCubit;

  setUp(() async {
    await locator.reset();
    clientPolicyRepository = _FakeStartupClientPolicyRepository();
    metadataProvider = _FakeAppClientMetadataProvider(
      const AppClientMetadata(
        platform: 'android',
        appVersion: '1.2.3',
        build: 42,
      ),
    );
    requestMyAccountDeletion = _FakeRequestMyAccountDeletion();
    appThemeCubit = AppThemeCubit(storage: _FakeThemeModeStorage());

    locator.registerFactory<RequestMyAccountDeletion>(() {
      return requestMyAccountDeletion;
    });
    locator.registerLazySingleton<StartupClientPolicyRepository>(
      () => clientPolicyRepository,
    );
    locator.registerLazySingleton<AppClientMetadataProvider>(
      () => metadataProvider,
    );

    OshAnalytics.debugSetBackend(const _NoopAnalyticsBackend());
    OshCrashReporter.debugSetBackend(const _NoopCrashReporterBackend());
  });

  tearDown(() async {
    OshAnalytics.debugResetBackend();
    OshCrashReporter.debugResetBackend();
    await appThemeCubit.close();
    await locator.reset();
  });

  testWidgets('hub renders profile summary, theme section, and about app',
      (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);

    await _pumpAccountSettingsPage(
      tester,
      authCubit: authCubit,
      appThemeCubit: appThemeCubit,
    );

    expect(find.text('Profile & settings'), findsOneWidget);
    expect(find.text('User Name'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('About app'), findsOneWidget);
    expect(find.text('App version'), findsOneWidget);
    expect(find.text('1.2.3 (42)'), findsOneWidget);
  });

  testWidgets('tapping profile card opens profile route', (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);

    await _pumpAccountSettingsPage(
      tester,
      authCubit: authCubit,
      appThemeCubit: appThemeCubit,
    );

    await tester.tap(find.text('User Name').first);
    await tester.pumpAndSettle();

    expect(find.byType(AccountProfilePage), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('tapping app version shows loading state while check runs',
      (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);
    clientPolicyRepository.inFlight = Completer<MobileClientPolicyDecision>();

    await _pumpAccountSettingsPage(
      tester,
      authCubit: authCubit,
      appThemeCubit: appThemeCubit,
    );

    await tester.tap(find.text('App version'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    clientPolicyRepository.inFlight!.complete(
      const MobileClientPolicyDecision(status: MobileClientPolicyStatus.allow),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('allow result shows success snackbar', (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);

    await _pumpAccountSettingsPage(
      tester,
      authCubit: authCubit,
      appThemeCubit: appThemeCubit,
    );

    await tester.tap(find.text('App version'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Latest version installed'), findsOneWidget);
  });

  testWidgets('fail-open result shows failure snackbar', (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);
    clientPolicyRepository.nextDecision = const MobileClientPolicyDecision(
      status: MobileClientPolicyStatus.allow,
      failOpen: true,
    );

    await _pumpAccountSettingsPage(
      tester,
      authCubit: authCubit,
      appThemeCubit: appThemeCubit,
    );

    await tester.tap(find.text('App version'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Unable to check for updates'), findsOneWidget);
  });

  testWidgets('recommend-update result presents recommend dialog',
      (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);
    clientPolicyRepository.nextDecision = MobileClientPolicyDecision(
      status: MobileClientPolicyStatus.recommendUpdate,
      policy: _samplePolicy,
    );

    await _pumpAccountSettingsPage(
      tester,
      authCubit: authCubit,
      appThemeCubit: appThemeCubit,
    );

    await tester.tap(find.text('App version'));
    await tester.pumpAndSettle();

    expect(find.text('A new app version is available'), findsOneWidget);
  });

  testWidgets('require-update result presents blocking fullscreen flow',
      (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);
    clientPolicyRepository.nextDecision = MobileClientPolicyDecision(
      status: MobileClientPolicyStatus.requireUpdate,
      policy: _samplePolicy,
    );

    await _pumpAccountSettingsPage(
      tester,
      authCubit: authCubit,
      appThemeCubit: appThemeCubit,
    );

    await tester.tap(find.text('App version'));
    await tester.pumpAndSettle();

    expect(find.text('Update app to continue'), findsOneWidget);
  });

  testWidgets('profile page shows verified-email state without CTA',
      (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);
    final cubit = _createAccountSettingsCubit(appThemeCubit);
    addTearDown(cubit.close);

    await _pumpProfilePage(
      tester,
      authCubit: authCubit,
      cubit: cubit,
    );

    expect(find.text('Email verified'), findsOneWidget);
    expect(find.text('Verify your email'), findsNothing);
  });

  testWidgets('profile page shows CTA for unverified non-demo user',
      (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: false),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);
    final cubit = _createAccountSettingsCubit(appThemeCubit);
    addTearDown(cubit.close);

    await _pumpProfilePage(
      tester,
      authCubit: authCubit,
      cubit: cubit,
    );

    expect(find.text('Email not verified'), findsOneWidget);
    expect(find.text('Verify your email'), findsOneWidget);
  });

  testWidgets('profile page hides verification status in demo mode',
      (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: false),
      isDemoMode: true,
    );
    addTearDown(authCubit.close);
    final cubit = _createAccountSettingsCubit(appThemeCubit);
    addTearDown(cubit.close);

    await _pumpProfilePage(
      tester,
      authCubit: authCubit,
      cubit: cubit,
    );

    expect(find.text('Demo mode'), findsOneWidget);
    expect(find.text('Email not verified'), findsNothing);
    expect(find.text('Verify your email'), findsNothing);
  });

  testWidgets('delete account row opens deletion flow', (tester) async {
    final authCubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(authCubit.close);
    final cubit = _createAccountSettingsCubit(appThemeCubit);
    addTearDown(cubit.close);

    await _pumpProfilePage(
      tester,
      authCubit: authCubit,
      cubit: cubit,
    );

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountDeletionRequestPage), findsOneWidget);
    expect(find.text('Confirm account deletion'), findsOneWidget);
  });
}

Future<void> _pumpAccountSettingsPage(
  WidgetTester tester, {
  required GlobalAuthCubit authCubit,
  required AppThemeCubit appThemeCubit,
}) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AppThemeCubit>.value(value: appThemeCubit),
        BlocProvider<GlobalAuthCubit>.value(value: authCubit),
      ],
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const AccountSettingsPage(),
      ),
    ),
  );

  await tester.pump();
  await tester.pump();
}

Future<void> _pumpProfilePage(
  WidgetTester tester, {
  required GlobalAuthCubit authCubit,
  required AccountSettingsCubit cubit,
}) async {
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<GlobalAuthCubit>.value(value: authCubit),
        BlocProvider<AccountSettingsCubit>.value(value: cubit),
      ],
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const AccountProfilePage(),
      ),
    ),
  );

  await tester.pump();
  await tester.pump();
}

JwtUserData _user({required bool isEmailVerified}) {
  return JwtUserData(
    uuid: 'u-1',
    email: 'user@example.com',
    name: 'User Name',
    isAdmin: false,
    isEmailVerified: isEmailVerified,
  );
}

AccountSettingsCubit _createAccountSettingsCubit(
  AppThemeCubit appThemeCubit,
) {
  return AccountSettingsCubit(
    appThemeCubit: appThemeCubit,
    requestMyAccountDeletion: _FakeRequestMyAccountDeletion(),
    clientPolicyRepository: _FakeStartupClientPolicyRepository(),
    appClientMetadataProvider: _FakeAppClientMetadataProvider(
      const AppClientMetadata(
        platform: 'android',
        appVersion: '1.2.3',
        build: 42,
      ),
    ),
  );
}

final MobileClientPolicy _samplePolicy = MobileClientPolicy(
  minSupportedVersion: '1.0.0',
  latestVersion: '2.0.0',
  storeUrl: 'https://example.com/store',
  policyVersion: 12,
  checkedAt: DateTime.utc(2026, 4, 16, 12),
  fetchedAt: DateTime.utc(2026, 4, 16, 12),
);

class _FakeThemeModeStorage implements ThemeModeStorage {
  @override
  ThemeMode readThemeMode() => ThemeMode.system;

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {}
}

class _FakeRequestMyAccountDeletion extends RequestMyAccountDeletion {
  _FakeRequestMyAccountDeletion()
      : super(mobileService: _FakeMobileV1Service());
}

class _FakeStartupClientPolicyRepository
    implements StartupClientPolicyRepository {
  MobileClientPolicyDecision nextDecision = const MobileClientPolicyDecision(
    status: MobileClientPolicyStatus.allow,
  );
  Completer<MobileClientPolicyDecision>? inFlight;

  @override
  Future<MobileClientPolicyDecision> checkPolicy() async {
    if (inFlight != null) {
      return inFlight!.future;
    }
    return nextDecision;
  }

  @override
  Future<void> suppressRecommendPrompt({required int policyVersion}) async {}
}

class _FakeAppClientMetadataProvider implements AppClientMetadataProvider {
  _FakeAppClientMetadataProvider(this.metadata);

  final AppClientMetadata metadata;

  @override
  Future<AppClientMetadata> getMetadata() async => metadata;
}

class _FakeMobileV1Service extends MobileV1Service {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestGlobalAuthCubit extends GlobalAuthCubit {
  _TestGlobalAuthCubit({
    required JwtUserData? userData,
    required bool isDemoMode,
  })  : _userData = userData,
        _isDemoMode = isDemoMode,
        super(
          authService: AuthService.create(),
          mobileService: MobileV1Service.create(),
          sessionStorage: SessionStorage(storage: const FlutterSecureStorage()),
          keycloakWrapper: KeycloakWrapper(),
        );

  final JwtUserData? _userData;
  final bool _isDemoMode;

  @override
  JwtUserData? getJwtUserData() {
    return _userData;
  }

  @override
  bool get isDemoMode => _isDemoMode;
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

class _NoopCrashReporterBackend implements CrashReporterBackend {
  const _NoopCrashReporterBackend();

  @override
  void log(String message) {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) async {}

  @override
  Future<void> recordFlutterFatalError(FlutterErrorDetails details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setCustomKey(String key, Object value) async {}

  @override
  Future<void> setUserId(String userId) async {}
}
