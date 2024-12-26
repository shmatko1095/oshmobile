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

/// Base class for failure states
abstract class AuthFailed extends AuthState {
  final String? message;

  const AuthFailed([this.message]);
}

final class AuthConflict extends AuthFailed {
  const AuthConflict() : super();
}

final class AuthFailedNoInternetConnection extends AuthFailed {
  const AuthFailedNoInternetConnection() : super();
}

final class AuthFailedInvalidUserCredentials extends AuthFailed {
  const AuthFailedInvalidUserCredentials() : super();
}

final class AuthFailedEmailNotVerified extends AuthFailed {
  const AuthFailedEmailNotVerified() : super();
}

final class AuthFailedUnexpected extends AuthFailed {
  const AuthFailedUnexpected(super.error);
}
