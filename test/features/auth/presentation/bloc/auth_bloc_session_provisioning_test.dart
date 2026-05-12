import 'package:fpdart/fpdart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/session_provisioning_failure.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/chopper_client/auth/auth_service.dart';
import 'package:oshmobile/core/network/chopper_client/core/session_storage.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/auth/domain/repository/auth_repository.dart';
import 'package:oshmobile/features/auth/domain/usecases/reset_password.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in_demo.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in_google.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_up.dart';
import 'package:oshmobile/features/auth/domain/usecases/verify_email.dart';
import 'package:oshmobile/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  late _FakeAuthRepository authRepository;
  late _TestGlobalAuthCubit globalAuthCubit;
  late AuthBloc bloc;

  setUp(() {
    OshAnalytics.debugSetBackend(const _NoopAnalyticsBackend());
    OshCrashReporter.debugSetBackend(const _NoopCrashReporterBackend());
    authRepository = _FakeAuthRepository();
    globalAuthCubit = _TestGlobalAuthCubit();
    bloc = AuthBloc(
      signUp: SignUp(authRepository: authRepository),
      signIn: SignIn(authRepository: authRepository),
      signInDemo: SignInDemo(authRepository: authRepository),
      signInWithGoogle: SignInWithGoogle(authRepository: authRepository),
      verifyEmail: VerifyEmail(authRepository: authRepository),
      resetPassword: ResetPassword(authRepository: authRepository),
      globalAuthCubit: globalAuthCubit,
    );
  });

  tearDown(() async {
    await bloc.close();
    await globalAuthCubit.close();
    OshAnalytics.debugResetBackend();
    OshCrashReporter.debugResetBackend();
  });

  test('transient provisioning failure becomes controlled no-internet state',
      () async {
    globalAuthCubit.signedInFailure = const SessionProvisioningException(
      kind: SessionProvisioningFailureKind.transient,
      message: 'Backend unavailable',
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthLoading>(),
        isA<AuthFailedNoInternetConnection>(),
      ]),
    );

    bloc.add(AuthSignIn(email: 'user@example.com', password: 'password'));
    await expectation;
  });

  test('auth rejected provisioning failure becomes controlled auth failure',
      () async {
    globalAuthCubit.signedInFailure = const SessionProvisioningException(
      kind: SessionProvisioningFailureKind.authRejected,
      message: 'User not found',
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<AuthLoading>(),
        isA<AuthFailedUnexpected>(),
      ]),
    );

    bloc.add(AuthSignIn(email: 'user@example.com', password: 'password'));
    await expectation;
  });
}

class _FakeAuthRepository implements AuthRepository {
  Session session = Session(
    accessToken: 'access',
    refreshToken: 'refresh',
    tokenType: 'Bearer',
  );

  @override
  Future<Either<Failure, Session>> signIn({
    required String email,
    required String password,
  }) async {
    return right(session);
  }

  @override
  Future<Either<Failure, Session>> signInWithGoogle() async => right(session);

  @override
  Future<Either<Failure, Session>> signInDemo() async => right(session);

  @override
  Future<Either<Failure, void>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    return right(null);
  }

  @override
  Future<Either<Failure, void>> verifyEmail({required String email}) async {
    return right(null);
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    return right(null);
  }
}

class _TestGlobalAuthCubit extends GlobalAuthCubit {
  _TestGlobalAuthCubit()
      : super(
          authService: AuthService.create(),
          mobileService: MobileV1Service.create(),
          sessionStorage: SessionStorage(storage: const FlutterSecureStorage()),
          keycloakWrapper: KeycloakWrapper(),
        );

  SessionProvisioningException? signedInFailure;

  @override
  Future<void> signedIn(Session session) async {
    final failure = signedInFailure;
    if (failure != null) {
      throw failure;
    }
  }
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
