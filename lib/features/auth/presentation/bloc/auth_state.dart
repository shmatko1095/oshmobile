part of 'auth_bloc.dart';

@immutable
sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthSuccess extends AuthState {
  final String message;
  const AuthSuccess(this.message);
}

final class AuthFailed extends AuthState {
  final String error;
  const AuthFailed(this.error);
}