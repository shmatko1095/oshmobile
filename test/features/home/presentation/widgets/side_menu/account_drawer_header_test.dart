import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/jwt_user_data.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/home/presentation/widgets/side_menu/account_drawer_header.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('verified user does not show verify-email badge',
      (WidgetTester tester) async {
    final cubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: true),
      isDemoMode: false,
    );
    addTearDown(cubit.close);

    await _pumpHeader(tester, cubit);

    expect(find.text('Verify your email'), findsNothing);
    expect(find.text('Demo mode'), findsNothing);
  });

  testWidgets('unverified user shows verify-email badge',
      (WidgetTester tester) async {
    final cubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: false),
      isDemoMode: false,
    );
    addTearDown(cubit.close);

    await _pumpHeader(tester, cubit);

    expect(find.text('Verify your email'), findsOneWidget);
  });

  testWidgets('demo mode hides verify-email badge',
      (WidgetTester tester) async {
    final cubit = _TestGlobalAuthCubit(
      userData: _user(isEmailVerified: false),
      isDemoMode: true,
    );
    addTearDown(cubit.close);

    await _pumpHeader(tester, cubit);

    expect(find.text('Demo mode'), findsOneWidget);
    expect(find.text('Verify your email'), findsNothing);
  });
}

Future<void> _pumpHeader(
  WidgetTester tester,
  GlobalAuthCubit cubit,
) async {
  await tester.pumpWidget(
    BlocProvider<GlobalAuthCubit>.value(
      value: cubit,
      child: MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: AccountDrawerHeader(),
        ),
      ),
    ),
  );

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
          keycloakWrapper: KeycloakWrapper(
            config: KeycloakConfig(
              bundleIdentifier: 'com.example.test',
              clientId: 'client',
              clientSecret: 'secret',
              frontendUrl: 'https://example.com',
              realm: 'realm',
            ),
          ),
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
