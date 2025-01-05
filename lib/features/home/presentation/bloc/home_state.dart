part of 'home_cubit.dart';

@immutable
sealed class HomeState {
  const HomeState();
}

final class HomeInitial extends HomeState {}

final class HomeReady extends HomeState {
  final List<Device> userDevices;

  const HomeReady({required this.userDevices});
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeFailed extends HomeState {
  final String? message;

  const HomeFailed([this.message]);
}
