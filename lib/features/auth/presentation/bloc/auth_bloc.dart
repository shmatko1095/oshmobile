import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/auth/domain/usecases/reset_password.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_in_google.dart';
import 'package:oshmobile/features/auth/domain/usecases/sign_up.dart';
import 'package:oshmobile/features/auth/domain/usecases/verify_email.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUp _signUp;
  final SignIn _signIn;
  final SignInWithGoogle _signInWithGoogle;
  final VerifyEmail _verifyEmail;
  final ResetPassword _resetPassword;
  final GlobalAuthCubit _globalAuthCubit;

  AuthBloc({
    required SignUp signUp,
    required SignIn signIn,
    required SignInWithGoogle signInWithGoogle,
    required VerifyEmail verifyEmail,
    required ResetPassword resetPassword,
    required GlobalAuthCubit globalAuthCubit,
  })  : _signUp = signUp,
        _signIn = signIn,
        _signInWithGoogle = signInWithGoogle,
        _verifyEmail = verifyEmail,
        _resetPassword = resetPassword,
        _globalAuthCubit = globalAuthCubit,
        super(const AuthInitial()) {
    on<AuthSignUp>(_onAuthSignUp);
    on<AuthSignIn>(_onAuthSignIn);
    on<AuthSignInWithGoogle>(_onSignInWithGoogle);
    on<AuthSendVerifyEmail>(_onAuthSendVerifyEmail);
    on<AuthSendResetPasswordEmail>(_onSendResetPasswordEmail);
  }

  void _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final response = await _signUp(
      UserSignUpParams(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
      ),
    );
    response.fold(
      (l) => _emitAuthFailure(emit, l),
      (r) => emit(AuthSuccess("Success")),
    );
  }

  void _onAuthSignIn(AuthSignIn event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final response = await _signIn(
      SignInParams(
        email: event.email,
        password: event.password,
      ),
    );
    response.fold(
      (l) => _emitAuthFailure(emit, l),
      (r) => _emitAuthSuccess(emit, r),
    );
  }

  Future<void> _onSignInWithGoogle(AuthSignInWithGoogle event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _signInWithGoogle(NoParams());
    result.fold(
      (l) => _emitAuthFailure(emit, l),
      (r) => _emitAuthSuccess(emit, r),
    );
  }

  void _onAuthSendVerifyEmail(AuthSendVerifyEmail event, Emitter<AuthState> emit) async {
    final response = await _verifyEmail(VerifyEmailParams(email: event.email));
    response.fold((l) => _emitAuthFailure(emit, l), (r) {});
  }

  void _onSendResetPasswordEmail(AuthSendResetPasswordEmail event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final response = await _resetPassword(ResetPasswordParams(email: event.email));
    response.fold(
      (l) => _emitAuthFailure(emit, l),
      (r) => emit(AuthSuccess("Success")),
    );
  }

  void _emitAuthSuccess(Emitter<AuthState> emit, Session session) {
    _globalAuthCubit.signedIn(session);
    emit(AuthSuccess("Success"));
  }

  void _emitAuthFailure(Emitter<AuthState> emit, Failure failure) {
    switch (failure.type) {
      case FailureType.emailNotVerified:
        emit(const AuthFailedEmailNotVerified());
      case FailureType.noInternetConnection:
        emit(const AuthFailedNoInternetConnection());
      case FailureType.invalidUserCredentials:
        emit(const AuthFailedInvalidUserCredentials());
      case FailureType.unexpected:
        emit(AuthFailedUnexpected(failure.message));
      case FailureType.conflict:
        emit(const AuthConflict());
    }
  }
}
