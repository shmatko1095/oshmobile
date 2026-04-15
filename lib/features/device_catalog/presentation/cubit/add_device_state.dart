part of 'add_device_cubit.dart';

enum AddDeviceStatus {
  idle,
  submitting,
  success,
  failure,
}

class AddDeviceState {
  final AddDeviceStatus status;
  final String? errorMessage;

  const AddDeviceState({
    this.status = AddDeviceStatus.idle,
    this.errorMessage,
  });

  AddDeviceState copyWith({
    AddDeviceStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddDeviceState(
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
