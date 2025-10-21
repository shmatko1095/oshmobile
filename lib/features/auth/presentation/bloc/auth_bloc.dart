import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/global_auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/auth/domain/usecases/reset_password.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signin.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signup.dart';
import 'package:oshmobile/features/auth/domain/usecases/verify_email.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserSignUp _userSignUp;
  final UserSignIn _userSignIn;
  final VerifyEmail _verifyEmail;
  final ResetPassword _resetPassword;
  final GlobalAuthCubit _globalAuthCubit;

  AuthBloc({
    required UserSignUp userSignUp,
    required UserSignIn userSignIn,
    required VerifyEmail verifyEmail,
    required ResetPassword resetPassword,
    required GlobalAuthCubit globalAuthCubit,
  })  : _userSignUp = userSignUp,
        _userSignIn = userSignIn,
        _verifyEmail = verifyEmail,
        _resetPassword = resetPassword,
        _globalAuthCubit = globalAuthCubit,
        super(const AuthInitial()) {
    on<AuthSignUp>(_onAuthSignUp);
    on<AuthSignIn>(_onAuthSignIn);
    on<AuthSendVerifyEmail>(_onAuthSendVerifyEmail);
    on<AuthSendResetPasswordEmail>(_onSendResetPasswordEmail);
  }

  void _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final response = await _userSignUp(
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
    final response = await _userSignIn(
      UserSignInParams(
        email: event.email,
        password: event.password,
      ),
    );
    response.fold(
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
