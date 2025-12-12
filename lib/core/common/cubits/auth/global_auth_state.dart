part of 'global_auth_cubit.dart';

@immutable
sealed class GlobalAuthState {
  /// Increases on every meaningful auth change:
  /// - sign in
  /// - sign out
  /// - token refresh
  ///
  /// Useful for listeners that must react even when the auth "type" stays the same.
  final int revision;

  const GlobalAuthState({required this.revision});
}

final class AuthInitial extends GlobalAuthState {
  const AuthInitial({required super.revision});
}

final class AuthAuthenticated extends GlobalAuthState {
  const AuthAuthenticated({required super.revision});
}
