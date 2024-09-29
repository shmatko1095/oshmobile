part of 'app_user_cubit.dart';

@immutable
sealed class AppUserState {
  const AppUserState();
}

final class AppUserInitial extends AppUserState {
  const AppUserInitial();
}

final class AppUserSignedIn extends AppUserState {
  final User user;

  const AppUserSignedIn({required this.user});
}
