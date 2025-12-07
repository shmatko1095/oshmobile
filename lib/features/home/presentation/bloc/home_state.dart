part of 'home_cubit.dart';

@immutable
abstract class HomeState {
  /// Id of currently selected device (if any).
  final String? selectedDeviceId;

  const HomeState({this.selectedDeviceId});

  /// Must be overridden in subclasses to preserve the concrete type.
  HomeState copyWith({String? selectedDeviceId});
}

final class HomeInitial extends HomeState {
  const HomeInitial({super.selectedDeviceId});

  @override
  HomeInitial copyWith({String? selectedDeviceId}) {
    return HomeInitial(
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}

final class HomeReady extends HomeState {
  const HomeReady({required super.selectedDeviceId});

  @override
  HomeReady copyWith({String? selectedDeviceId}) {
    return HomeReady(
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}

final class HomeLoading extends HomeState {
  const HomeLoading({required super.selectedDeviceId});

  @override
  HomeLoading copyWith({String? selectedDeviceId}) {
    return HomeLoading(
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}

final class HomeFailed extends HomeState {
  final String? message;

  const HomeFailed(
    this.message, {
    required super.selectedDeviceId,
  });

  @override
  HomeFailed copyWith({String? selectedDeviceId}) {
    return HomeFailed(
      message,
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}

final class HomeAssignFailed extends HomeState {
  const HomeAssignFailed({required super.selectedDeviceId});

  @override
  HomeAssignFailed copyWith({String? selectedDeviceId}) {
    return HomeAssignFailed(
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}

final class HomeAssignDone extends HomeState {
  const HomeAssignDone({required super.selectedDeviceId});

  @override
  HomeAssignDone copyWith({String? selectedDeviceId}) {
    return HomeAssignDone(
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}

final class HomeUpdateDeviceUserDataFailed extends HomeState {
  const HomeUpdateDeviceUserDataFailed({required super.selectedDeviceId});

  @override
  HomeUpdateDeviceUserDataFailed copyWith({String? selectedDeviceId}) {
    return HomeUpdateDeviceUserDataFailed(
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}

final class HomeUpdateDeviceUserDataDone extends HomeState {
  const HomeUpdateDeviceUserDataDone({required super.selectedDeviceId});

  @override
  HomeUpdateDeviceUserDataDone copyWith({String? selectedDeviceId}) {
    return HomeUpdateDeviceUserDataDone(
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
    );
  }
}
