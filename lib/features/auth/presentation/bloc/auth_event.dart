part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthSignUp extends AuthEvent {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;

  AuthSignUp({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName
  });
}

final class AuthSignIn extends AuthEvent {
  final String email;
  final String password;

  AuthSignIn({
    required this.email,
    required this.password,
  });
}

final class AuthIsUserSignedIn extends AuthEvent {}
