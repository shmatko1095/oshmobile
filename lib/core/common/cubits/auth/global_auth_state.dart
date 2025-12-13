part of 'global_auth_cubit.dart';

/// Auth state MUST change identity whenever we want listeners to react
/// (for example after refresh token).
///
/// Using `const AuthAuthenticated()` repeatedly will be treated as the *same*
/// instance and Cubit won't emit updates. We keep a monotonically increasing
/// [revision] to force emissions when needed.
@immutable
sealed class GlobalAuthState {
  final int revision;
  const GlobalAuthState(this.revision);
}

final class AuthInitial extends GlobalAuthState {
  const AuthInitial(super.revision);
}

final class AuthAuthenticated extends GlobalAuthState {
  const AuthAuthenticated(super.revision);
}
