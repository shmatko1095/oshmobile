part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthSignUp extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  AuthSignUp({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
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

final class AuthSignInWithGoogle extends AuthEvent {
  AuthSignInWithGoogle();
}

final class AuthSendVerifyEmail extends AuthEvent {
  final String email;

  AuthSendVerifyEmail({
    required this.email,
  });
}

final class AuthSendResetPasswordEmail extends AuthEvent {
  final String email;

  AuthSendResetPasswordEmail({
    required this.email,
  });
}
