import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/cubits/auth/session_provisioning_failure.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/presentation/errors/rest_error_localizer.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/auth/domain/usecases/reset_password.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in_demo.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in_google.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_up.dart';
import 'package:oshmobile/features/auth/domain/usecases/verify_email.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUp _signUp;
  final SignIn _signIn;
  final SignInDemo _signInDemo;
  final SignInWithGoogle _signInWithGoogle;
  final VerifyEmail _verifyEmail;
  final ResetPassword _resetPassword;
  final GlobalAuthCubit _globalAuthCubit;

  AuthBloc({
    required SignUp signUp,
    required SignIn signIn,
    required SignInDemo signInDemo,
    required SignInWithGoogle signInWithGoogle,
    required VerifyEmail verifyEmail,
    required ResetPassword resetPassword,
    required GlobalAuthCubit globalAuthCubit,
  })  : _signUp = signUp,
        _signIn = signIn,
        _signInDemo = signInDemo,
        _signInWithGoogle = signInWithGoogle,
        _verifyEmail = verifyEmail,
        _resetPassword = resetPassword,
        _globalAuthCubit = globalAuthCubit,
        super(const AuthInitial()) {
    on<AuthSignUp>(_onAuthSignUp);
    on<AuthSignIn>(_onAuthSignIn);
    on<AuthSignInDemo>(_onSignInDemo);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSendVerifyEmail>(_onAuthSendVerifyEmail);
    on<AuthSendResetPasswordEmail>(_onSendResetPasswordEmail);
  }

  Future<void> _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final response = await _signUp(
      UserSignUpParams(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
      ),
    );
    await response.fold(
      (l) async => _emitFailureState(emit, l),
      (r) async {
        await OshAnalytics.logEvent(OshAnalyticsEvents.authSignUpSucceeded);
        emit(AuthSuccess("Success"));
      },
    );
  }

  Future<void> _onAuthSignIn(AuthSignIn event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final response = await _signIn(
      SignInParams(
        email: event.email,
        password: event.password,
      ),
    );
    await response.fold(
      (l) => _emitAuthFailure(emit, l, provider: 'password'),
      (r) => _emitAuthSuccess(emit, r, provider: 'password'),
    );
  }

  Future<void> _onSignInWithGoogle(
      AuthSignInWithGoogle event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _signInWithGoogle(NoParams());
    await result.fold(
      (l) => _emitAuthFailure(emit, l, provider: 'google'),
      (r) => _emitAuthSuccess(emit, r, provider: 'google'),
    );
  }

  Future<void> _onSignInDemo(
      AuthSignInDemo event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _signInDemo(NoParams());
    await result.fold(
      (l) => _emitAuthFailure(emit, l, provider: 'demo'),
      (r) => _emitAuthSuccess(emit, r, provider: 'demo'),
    );
  }

  Future<void> _onAuthSendVerifyEmail(
      AuthSendVerifyEmail event, Emitter<AuthState> emit) async {
    final response = await _verifyEmail(VerifyEmailParams(email: event.email));
    await response.fold(
      (l) async => _emitFailureState(emit, l),
      (r) async {},
    );
  }

  Future<void> _onSendResetPasswordEmail(
      AuthSendResetPasswordEmail event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final response =
        await _resetPassword(ResetPasswordParams(email: event.email));
    await response.fold(
      (l) async => _emitFailureState(emit, l),
      (r) async {
        await OshAnalytics.logEvent(
          OshAnalyticsEvents.authPasswordResetRequested,
        );
        emit(AuthSuccess("Success"));
      },
    );
  }

  Future<void> _emitAuthSuccess(
    Emitter<AuthState> emit,
    Session session, {
    required String provider,
  }) async {
    try {
      await _globalAuthCubit.signedIn(session);
    } on SessionProvisioningException catch (failure, st) {
      await _emitProvisioningFailure(emit, failure, st, provider: provider);
      return;
    }
    await OshAnalytics.logEvent(
      OshAnalyticsEvents.authSignInSucceeded,
      parameters: {'provider': provider},
    );
    emit(AuthSuccess("Success"));
  }

  Future<void> _emitProvisioningFailure(
    Emitter<AuthState> emit,
    SessionProvisioningException failure,
    StackTrace stackTrace, {
    required String provider,
  }) async {
    await OshAnalytics.logEvent(
      OshAnalyticsEvents.authSignInFailed,
      parameters: {
        'provider': provider,
        'reason': failure.isTransient
            ? 'session_provisioning_transient'
            : 'session_provisioning_rejected',
      },
    );

    OshCrashReporter.logNonFatal(
      failure,
      stackTrace,
      reason: 'Session provisioning failed during sign-in',
    );

    if (failure.isTransient) {
      emit(const AuthFailedNoInternetConnection());
      return;
    }

    emit(AuthFailedUnexpected(
      'Sign in could not be completed. Please sign in again.',
    ));
  }

  Future<void> _emitAuthFailure(
    Emitter<AuthState> emit,
    Failure failure, {
    required String provider,
  }) async {
    await OshAnalytics.logEvent(
      OshAnalyticsEvents.authSignInFailed,
      parameters: {
        'provider': provider,
        'reason': _analyticsReasonForFailure(failure),
      },
    );

    _emitFailureState(emit, failure);
  }

  void _emitFailureState(Emitter<AuthState> emit, Failure failure) {
    switch (failure.type) {
      case FailureType.emailNotVerified:
        emit(const AuthFailedEmailNotVerified());
        return;
      case FailureType.noInternetConnection:
        emit(const AuthFailedNoInternetConnection());
        return;
      case FailureType.invalidUserCredentials:
        emit(const AuthFailedInvalidUserCredentials());
        return;
      case FailureType.unexpected:
        final message = RestErrorLocalizer.resolveFailure(failure);
        OshCrashReporter.log(
            "AuthBloc: Unexpected failure: ${failure.message}");
        emit(AuthFailedUnexpected(message));
        return;
      case FailureType.conflict:
        emit(const AuthConflict());
        return;
    }
  }

  String _analyticsReasonForFailure(Failure failure) {
    return switch (failure.type) {
      FailureType.emailNotVerified => 'email_not_verified',
      FailureType.noInternetConnection => 'no_internet',
      FailureType.invalidUserCredentials => 'invalid_credentials',
      FailureType.unexpected => 'unexpected',
      FailureType.conflict => 'conflict',
    };
  }
}
