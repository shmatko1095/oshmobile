part of 'device_access_cubit.dart';

const _unsetCurrentUserUuid = Object();

enum DeviceAccessStatus {
  initial,
  loading,
  ready,
  failure,
}

class DeviceAccessState {
  final DeviceAccessStatus status;
  final List<DeviceAssignedUser> users;
  final String? currentUserUuid;
  final String? errorMessage;

  const DeviceAccessState({
    this.status = DeviceAccessStatus.initial,
    this.users = const <DeviceAssignedUser>[],
    this.currentUserUuid,
    this.errorMessage,
  });

  DeviceAccessState copyWith({
    DeviceAccessStatus? status,
    List<DeviceAssignedUser>? users,
    Object? currentUserUuid = _unsetCurrentUserUuid,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeviceAccessState(
      status: status ?? this.status,
      users: users ?? this.users,
      currentUserUuid: identical(currentUserUuid, _unsetCurrentUserUuid)
          ? this.currentUserUuid
          : currentUserUuid as String?,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
