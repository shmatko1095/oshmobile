import 'package:chopper/chopper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/auth_interceptor.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';

void main() {
  test('adds Authorization from stored session before authenticated state',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final secureStorage = _MemorySecureStorage()..install();
    final storage = SessionStorage(storage: const FlutterSecureStorage());
    await storage.initialize();
    await storage.setSession(
      Session(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          tokenType: 'Bearer'),
    );
    final authCubit = GlobalAuthCubit(
      authService: AuthService.create(),
      mobileService: MobileV1Service.create(),
      sessionStorage: storage,
      keycloakWrapper: KeycloakWrapper(),
    );
    final interceptor = AuthInterceptor(globalAuthCubit: authCubit);
    final request = Request(
      'POST',
      Uri.parse('https://api.oshhome.com/v1/mobile/me/session'),
      Uri.parse('https://api.oshhome.com'),
    );

    final chain = _RecordingChain<dynamic>(request);
    await interceptor.intercept(chain);

    expect(chain.forwardedRequest, isNotNull);
    expect(
      chain.forwardedRequest!.headers['authorization'],
      'Bearer access-token',
    );

    await authCubit.close();
    secureStorage.uninstall();
  });
}

class _RecordingChain<BodyType> implements Chain<BodyType> {
  _RecordingChain(this.request);

  @override
  final Request request;

  Request? forwardedRequest;

  @override
  Future<Response<BodyType>> proceed(Request request) async {
    forwardedRequest = request;
    return Response<BodyType>(http.Response('', 200), null);
  }
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
