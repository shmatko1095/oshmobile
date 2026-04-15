part of 'device_management_cubit.dart';

enum DeviceManagementStatus {
  idle,
  submitting,
  success,
  failure,
}

enum DeviceManagementAction {
  rename,
  remove,
}

class DeviceManagementState {
  final DeviceManagementStatus status;
  final DeviceManagementAction? action;
  final String? errorMessage;

  const DeviceManagementState({
    this.status = DeviceManagementStatus.idle,
    this.action,
    this.errorMessage,
  });

  DeviceManagementState copyWith({
    DeviceManagementStatus? status,
    DeviceManagementAction? action,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeviceManagementState(
      status: status ?? this.status,
      action: action ?? this.action,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
