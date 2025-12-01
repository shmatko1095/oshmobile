import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:oshmobile/core/permissions/ble_permission_service.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_connect_status.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/disconnect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/observe_device_nearby.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/scan_wifi_networks.dart';

part 'ble_provisioning_state.dart';

class BleProvisioningCubit extends Cubit<BleProvisioningState> {
  final BlePermissionService _permissions;
  final ConnectBleDevice _connectBleDevice;
  final DisconnectBleDevice _disconnectBleDevice;
  final ScanWifiNetworks _scanWifiNetworks;
  final ConnectWifiNetwork _connectWifiNetwork;
  final ObserveDeviceNearby _observeDeviceNearby;

  StreamSubscription<List<WifiNetwork>>? _scanSub;
  StreamSubscription<WifiConnectStatus>? _wifiConnSub;
  StreamSubscription<bool>? _nearbySub;

  BleProvisioningCubit({
    required BlePermissionService permissions,
    required ConnectBleDevice connectBleDevice,
    required DisconnectBleDevice disconnectBleDevice,
    required ScanWifiNetworks scanWifiNetworks,
    required ConnectWifiNetwork connectWifiNetwork,
    required ObserveDeviceNearby observeDeviceNearby,
  })  : _permissions = permissions,
        _connectBleDevice = connectBleDevice,
        _disconnectBleDevice = disconnectBleDevice,
        _scanWifiNetworks = scanWifiNetworks,
        _connectWifiNetwork = connectWifiNetwork,
        _observeDeviceNearby = observeDeviceNearby,
        super(const BleProvisioningState.initial());

  Future<void> startNearbyCheck({
    required String serialNumber,
  }) async {
    final hasPerms = await _permissions.ensureBlePermissions();
    if (!hasPerms) {
      emit(state.copyWith(
        status: ProvisioningStatus.permissionDenied,
        deviceNearby: null,
        error: 'BLE permissions not granted',
      ));
      return;
    }

    await _nearbySub?.cancel();
    _nearbySub = null;

    emit(state.copyWith(
      status: ProvisioningStatus.searchingNearby,
      deviceNearby: null,
      error: null,
    ));

    _nearbySub = _observeDeviceNearby(serialNumber: serialNumber).listen(
      (isNearby) {
        emit(state.copyWith(
          status: ProvisioningStatus.searchingNearby,
          deviceNearby: isNearby,
          error: null,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: ProvisioningStatus.error,
          deviceNearby: null,
          error: 'Nearby check failed: $e',
        ));
      },
    );
  }

  Future<void> connect({
    required String serialNumber,
    required String secureCode,
  }) async {
    await _nearbySub?.cancel();
    _nearbySub = null;

    final hasPerms = await _permissions.ensureBlePermissions();
    if (!hasPerms) {
      emit(state.copyWith(
        status: ProvisioningStatus.permissionDenied,
        error: 'BLE permissions not granted',
      ));
      return;
    }

    emit(state.copyWith(
      status: ProvisioningStatus.connectingBle,
      error: null,
    ));

    try {
      await _connectBleDevice(
        serialNumber: serialNumber,
        secureCode: secureCode,
      );

      emit(state.copyWith(
        status: ProvisioningStatus.wifiScanIdle,
        error: null,
      ));

      await refreshScan();
    } catch (e) {
      emit(state.copyWith(
        status: ProvisioningStatus.error,
        error: 'Failed to connect via BLE: $e',
      ));
    }
  }

  Future<void> refreshScan() async {
    await _scanSub?.cancel();
    _scanSub = null;

    emit(state.copyWith(
      status: ProvisioningStatus.wifiScanInProgress,
      networks: const [],
      error: null,
    ));

    _scanSub = _scanWifiNetworks().listen(
      (networks) {
        emit(state.copyWith(
          status: ProvisioningStatus.wifiScanInProgress,
          networks: networks,
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: ProvisioningStatus.error,
          error: 'Wi-Fi scan failed: $e',
        ));
      },
      onDone: () {
        emit(state.copyWith(
          status: ProvisioningStatus.wifiScanDone,
        ));
      },
    );
  }

  void selectNetwork(WifiNetwork network) {
    emit(state.copyWith(
      selectedNetwork: network,
      status: ProvisioningStatus.enterPassword,
      error: null,
    ));
  }

  Future<void> connectWifi(String password) async {
    final network = state.selectedNetwork;
    if (network == null) return;

    await _wifiConnSub?.cancel();
    _wifiConnSub = null;

    emit(state.copyWith(
      status: ProvisioningStatus.wifiConnecting,
      lastConnectStatus: null,
      error: null,
    ));

    _wifiConnSub = _connectWifiNetwork(
      ssid: network.ssid,
      password: password,
    ).listen(
      (status) {
        emit(state.copyWith(
          lastConnectStatus: status,
          status: _mapConnectState(status),
        ));
      },
      onError: (e) {
        emit(state.copyWith(
          status: ProvisioningStatus.error,
          error: 'Wi-Fi connect failed: $e',
        ));
      },
    );
  }

  void resetForNewFlow() {
    emit(const BleProvisioningState.initial());
  }

  ProvisioningStatus _mapConnectState(WifiConnectStatus s) {
    switch (s.state) {
      case WifiConnectState.connecting:
      case WifiConnectState.obtainingIp:
        return ProvisioningStatus.wifiConnecting;
      case WifiConnectState.success:
        return ProvisioningStatus.wifiSuccess;
      case WifiConnectState.failed:
        return ProvisioningStatus.wifiFailed;
      case WifiConnectState.idle:
      default:
        return state.status;
    }
  }

  @override
  Future<void> close() async {
    await _scanSub?.cancel();
    await _wifiConnSub?.cancel();
    await _nearbySub?.cancel();
    await _disconnectBleDevice();
    return super.close();
  }
}
