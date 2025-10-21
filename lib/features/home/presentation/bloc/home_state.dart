part of 'home_cubit.dart';

@immutable
class HomeState {
  final String? selectedDeviceId;

  const HomeState({this.selectedDeviceId});

  HomeState copyWith({String? selectedDeviceId}) =>
      HomeState(selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId);
}

final class HomeInitial extends HomeState {
  const HomeInitial({super.selectedDeviceId});
}

final class HomeReady extends HomeState {
  const HomeReady({required super.selectedDeviceId});
}

final class HomeLoading extends HomeState {
  const HomeLoading({required super.selectedDeviceId});
}

final class HomeFailed extends HomeState {
  final String? message;

  const HomeFailed(this.message, {required super.selectedDeviceId});
}

final class HomeAssignFailed extends HomeState {
  const HomeAssignFailed({required super.selectedDeviceId});
}

final class HomeAssignDone extends HomeState {
  const HomeAssignDone({required super.selectedDeviceId});
}

final class HomeUpdateDeviceUserDataFailed extends HomeState {
  const HomeUpdateDeviceUserDataFailed({required super.selectedDeviceId});
}

final class HomeUpdateDeviceUserDataDone extends HomeState {
  const HomeUpdateDeviceUserDataDone({required super.selectedDeviceId});
}
