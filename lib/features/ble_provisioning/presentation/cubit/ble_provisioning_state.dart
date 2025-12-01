part of 'ble_provisioning_cubit.dart';

enum ProvisioningStatus {
  initial,
  searchingNearby,
  permissionDenied,
  connectingBle,
  wifiScanIdle,
  wifiScanInProgress,
  wifiScanDone,
  enterPassword,
  wifiConnecting,
  wifiSuccess,
  wifiFailed,
  error,
}

@immutable
class BleProvisioningState {
  final ProvisioningStatus status;
  final List<WifiNetwork> networks;
  final WifiNetwork? selectedNetwork;
  final WifiConnectStatus? lastConnectStatus;
  final String? error;
  final bool? deviceNearby;

  const BleProvisioningState({
    required this.status,
    required this.networks,
    required this.selectedNetwork,
    required this.lastConnectStatus,
    required this.error,
    required this.deviceNearby,
  });

  const BleProvisioningState.initial()
      : status = ProvisioningStatus.initial,
        networks = const [],
        selectedNetwork = null,
        lastConnectStatus = null,
        error = null,
        deviceNearby = false;

  BleProvisioningState copyWith({
    ProvisioningStatus? status,
    List<WifiNetwork>? networks,
    WifiNetwork? selectedNetwork,
    bool clearSelectedNetwork = false,
    WifiConnectStatus? lastConnectStatus,
    String? error,
    bool? deviceNearby,
  }) {
    return BleProvisioningState(
      status: status ?? this.status,
      networks: networks ?? this.networks,
      selectedNetwork: clearSelectedNetwork ? null : (selectedNetwork ?? this.selectedNetwork),
      lastConnectStatus: lastConnectStatus ?? this.lastConnectStatus,
      error: error,
      deviceNearby: deviceNearby ?? this.deviceNearby,
    );
  }
}
