part of 'device_catalog_cubit.dart';

const _unsetSelectedDeviceId = Object();

enum DeviceCatalogStatus {
  initial,
  loading,
  refreshing,
  ready,
  failure,
}

class DeviceCatalogState {
  final DeviceCatalogStatus status;
  final List<Device> devices;
  final String? selectedDeviceId;
  final String? errorMessage;

  const DeviceCatalogState({
    this.status = DeviceCatalogStatus.initial,
    this.devices = const <Device>[],
    this.selectedDeviceId,
    this.errorMessage,
  });

  DeviceCatalogState copyWith({
    DeviceCatalogStatus? status,
    List<Device>? devices,
    Object? selectedDeviceId = _unsetSelectedDeviceId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DeviceCatalogState(
      status: status ?? this.status,
      devices: devices ?? this.devices,
      selectedDeviceId: identical(selectedDeviceId, _unsetSelectedDeviceId)
          ? this.selectedDeviceId
          : selectedDeviceId as String?,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
