import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/session_provisioning_failure.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/common/entities/session_mode.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/startup/domain/contracts/startup_auth_bootstrapper.dart';

void main() {
  late _FakeAuthService authService;
  late _FakeMobileV1Service mobileService;
  late _MemorySecureStorage secureStorage;
  late SessionStorage sessionStorage;
  late GlobalAuthCubit cubit;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    OshAnalytics.debugSetBackend(const _NoopAnalyticsBackend());
    OshCrashReporter.debugSetBackend(const _NoopCrashReporterBackend());
    secureStorage = _MemorySecureStorage()..install();
    authService = _FakeAuthService();
    mobileService = _FakeMobileV1Service();
    sessionStorage = SessionStorage(storage: const FlutterSecureStorage());
    await sessionStorage.initialize();
    cubit = GlobalAuthCubit(
      authService: authService,
      mobileService: mobileService,
      sessionStorage: sessionStorage,
      keycloakWrapper: KeycloakWrapper(),
    );
  });

  tearDown(() async {
    await cubit.close();
    secureStorage.uninstall();
    OshAnalytics.debugResetBackend();
    OshCrashReporter.debugResetBackend();
  });

  test('signedIn ensures real session before authenticated state', () async {
    await cubit.signedIn(_realSession());

    expect(mobileService.ensureCalls, 1);
    expect(cubit.state, isA<AuthAuthenticated>());
    expect(sessionStorage.getSession(), isNotNull);
  });

  test('signedIn skips ensure for demo session', () async {
    await cubit.signedIn(_demoSession());

    expect(mobileService.ensureCalls, 0);
    expect(cubit.state, isA<AuthAuthenticated>());
  });

  test('transient ensure failure keeps pending session unauthenticated',
      () async {
    mobileService.ensureResponse = _response(503, {
      'message': 'Service unavailable',
    });

    final failure = await _expectProvisioningFailure(
      () => cubit.signedIn(_realSession()),
    );

    expect(failure.kind, SessionProvisioningFailureKind.transient);
    expect(mobileService.ensureCalls, 1);
    expect(sessionStorage.getSession(), isNotNull);
    expect(cubit.state, isA<AuthInitial>());
  });

  test('auth rejected ensure failure clears pending session', () async {
    mobileService.ensureResponse = _response(404, {
      'message': 'User not found',
    });

    final failure = await _expectProvisioningFailure(
      () => cubit.signedIn(_realSession()),
    );

    expect(failure.kind, SessionProvisioningFailureKind.authRejected);
    expect(sessionStorage.getSession(), isNull);
    expect(cubit.state, isA<AuthInitial>());
  });

  test('generic refreshToken does not call ensure', () async {
    await sessionStorage.setSession(_realSession(refreshToken: 'old-refresh'));
    authService.refreshResponse = _response(200, _sessionJson());

    final refreshed = await cubit.refreshToken();

    expect(refreshed, isTrue);
    expect(authService.refreshCalls, 1);
    expect(mobileService.ensureCalls, 0);
    expect(cubit.state, isA<AuthAuthenticated>());
  });

  test('startup bootstrap returns transientFailure without clearing session',
      () async {
    await sessionStorage.setSession(_realSession(refreshToken: 'old-refresh'));
    authService.refreshResponse = _response(200, _sessionJson());
    mobileService.ensureResponse = _response(500, {
      'message': 'Backend unavailable',
    });

    final result = await cubit.checkAuthStatus();

    expect(result, StartupAuthBootstrapResult.transientFailure);
    expect(mobileService.ensureCalls, 1);
    expect(sessionStorage.getSession(), isNotNull);
    expect(cubit.state, isA<AuthInitial>());
  });
}

Future<SessionProvisioningException> _expectProvisioningFailure(
  Future<void> Function() body,
) async {
  try {
    await body();
  } on SessionProvisioningException catch (error) {
    return error;
  }
  fail('Expected SessionProvisioningException');
}

Session _realSession({String refreshToken = 'refresh'}) {
  return Session(
    accessToken: _jwt(),
    refreshToken: refreshToken,
    tokenType: 'Bearer',
    authProvider: 'google',
    accessTokenExpiry: DateTime.now().add(const Duration(minutes: 5)),
    refreshTokenExpiry: DateTime.now().add(const Duration(hours: 1)),
  );
}

Session _demoSession() {
  return Session(
    accessToken: _jwt(),
    refreshToken: '',
    tokenType: 'Bearer',
    authProvider: 'demo',
    mode: SessionMode.demo,
  );
}

Map<String, dynamic> _sessionJson() => {
      'access_token': _jwt(),
      'refresh_token': 'new-refresh',
      'token_type': 'Bearer',
      'expires_in': 300,
      'refresh_expires_in': 3600,
    };

String _jwt() {
  String encode(Map<String, dynamic> value) {
    return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  }

  return [
    encode({'alg': 'none'}),
    encode({
      'sub': '11111111-1111-1111-1111-111111111111',
      'email': 'user@example.com',
      'name': 'Test User',
      'email_verified': true,
      'realm_access': {
        'roles': <String>[],
      },
    }),
    '',
  ].join('.');
}

Response<dynamic> _response(int statusCode, dynamic body) {
  return Response<dynamic>(http.Response('', statusCode), body);
}

const MethodChannel _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

class _MemorySecureStorage {
  final Map<String, String> _values = <String, String>{};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, _handleCall);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  }

  Future<Object?> _handleCall(MethodCall call) async {
    final args = (call.arguments as Map).cast<String, Object?>();
    final key = args['key'] as String?;
    switch (call.method) {
      case 'read':
        return _values[key];
      case 'write':
        _values[key!] = args['value'] as String;
        return null;
      case 'delete':
        _values.remove(key);
        return null;
      case 'deleteAll':
        _values.clear();
        return null;
      case 'containsKey':
        return _values.containsKey(key);
      case 'readAll':
        return Map<String, String>.of(_values);
    }
    return null;
  }
}

class _FakeAuthService extends AuthService {
  Response<dynamic>? refreshResponse;
  int refreshCalls = 0;

  @override
  Future<Response<dynamic>> refreshToken({
    required String refreshToken,
    String grantType = 'refresh_token',
    String clientId = '',
    String clientSecret = '',
  }) async {
    refreshCalls++;
    return refreshResponse ?? _response(200, _sessionJson());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMobileV1Service extends MobileV1Service {
  Response<dynamic>? ensureResponse;
  int ensureCalls = 0;

  @override
  Future<Response<dynamic>> ensureMySession() async {
    ensureCalls++;
    return ensureResponse ?? _response(204, null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAnalyticsBackend implements AnalyticsBackend {
  const _NoopAnalyticsBackend();

  @override
  Future<void> logEvent(String name,
      {Map<String, Object?>? parameters}) async {}

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
