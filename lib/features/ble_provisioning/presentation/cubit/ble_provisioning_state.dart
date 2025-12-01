part of 'ble_provisioning_cubit.dart';

enum ProvisioningStatus {
  initial,
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

  const BleProvisioningState({
    required this.status,
    required this.networks,
    required this.selectedNetwork,
    required this.lastConnectStatus,
    required this.error,
  });

  const BleProvisioningState.initial()
      : status = ProvisioningStatus.initial,
        networks = const [],
        selectedNetwork = null,
        lastConnectStatus = null,
        error = null;

  BleProvisioningState copyWith({
    ProvisioningStatus? status,
    List<WifiNetwork>? networks,
    WifiNetwork? selectedNetwork,
    bool clearSelectedNetwork = false,
    WifiConnectStatus? lastConnectStatus,
    String? error,
  }) {
    return BleProvisioningState(
      status: status ?? this.status,
      networks: networks ?? this.networks,
      selectedNetwork: clearSelectedNetwork ? null : (selectedNetwork ?? this.selectedNetwork),
      lastConnectStatus: lastConnectStatus ?? this.lastConnectStatus,
      error: error,
    );
  }
}
