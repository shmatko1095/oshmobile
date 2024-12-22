part of 'global_auth_cubit.dart';

@immutable
sealed class GlobalAuthState {
  const GlobalAuthState();
}

final class AuthInitial extends GlobalAuthState {
  const AuthInitial();
}

final class AuthAuthenticated extends GlobalAuthState {
  const AuthAuthenticated();
}