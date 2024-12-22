import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/global_auth/global_auth_cubit.dart';
import 'package:oshmobile/core/common/entities/session.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signin.dart';
import 'package:oshmobile/features/auth/domain/usecases/user_signup.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserSignUp _userSignUp;
  final UserSignIn _userSignIn;
  final GlobalAuthCubit _authCubit;

  AuthBloc({
    required UserSignUp userSignUp,
    required UserSignIn userSignIn,
    required GlobalAuthCubit globalAuthCubit,
  })  : _userSignUp = userSignUp,
        _userSignIn = userSignIn,
        _authCubit = globalAuthCubit,
        super(const AuthInitial()) {
    on<AuthEvent>(_onAuthLoading);
    on<AuthSignUp>(_onAuthSignUp);
    on<AuthSignIn>(_onAuthSignIn);
  }

  void _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    final response = await _userSignUp(
      UserSignUpParams(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
      ),
    );
    response.fold(
      (l) => emit(AuthFailed(l.message)),
      (r) => emit(AuthSuccess("Success")),
    );
  }

  void _onAuthSignIn(AuthSignIn event, Emitter<AuthState> emit) async {
    final response = await _userSignIn(
      UserSignInParams(
        email: event.email,
        password: event.password,
      ),
    );
    response.fold(
      (l) => emit(AuthFailed(l.message)),
      (r) => _emitAuthSuccess(emit, r),
    );
  }

  void _emitAuthSuccess(Emitter<AuthState> emit, Session session) {
    _authCubit.signedIn(session);
    emit(AuthSuccess("Success"));
  }

  void _onAuthLoading(AuthEvent event, Emitter<AuthState> emit) =>
      emit(const AuthLoading());
}
