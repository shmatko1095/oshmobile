import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:oshmobile/core/permissions/ble_permission_service.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_connect_status.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/connect_wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/disconnect_ble_device.dart';
import 'package:oshmobile/features/ble_provisioning/domain/usecases/scan_wifi_networks.dart';

part 'ble_provisioning_state.dart';

class BleProvisioningCubit extends Cubit<BleProvisioningState> {
  final BlePermissionService _permissions;
  final ConnectBleDevice _connectBle;
  final DisconnectBleDevice _disconnectBle;
  final ScanWifiNetworks _scanWifi;
  final ConnectWifiNetwork _connectWifi;

  StreamSubscription<List<WifiNetwork>>? _scanSub;
  StreamSubscription<WifiConnectStatus>? _connSub;

  BleProvisioningCubit({
    required BlePermissionService permissions,
    required ConnectBleDevice connectBle,
    required DisconnectBleDevice disconnectBle,
    required ScanWifiNetworks scanWifi,
    required ConnectWifiNetwork connectWifi,
  })  : _permissions = permissions,
        _connectBle = connectBle,
        _disconnectBle = disconnectBle,
        _scanWifi = scanWifi,
        _connectWifi = connectWifi,
        super(const BleProvisioningState.initial());

  Future<void> start({
    required String serialNumber,
    required String secureCode,
  }) async {
    final hasPerms = await _permissions.ensureBlePermissions();
    if (!hasPerms) {
      emit(state.copyWith(
        status: ProvisioningStatus.permissionDenied,
        error: 'BLE permissions not granted',
      ));
      return;
    }

    emit(state.copyWith(status: ProvisioningStatus.connectingBle, error: null));
    try {
      await _connectBle(serialNumber: serialNumber, secureCode: secureCode);
      emit(state.copyWith(status: ProvisioningStatus.wifiScanIdle));
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
    emit(state.copyWith(
      status: ProvisioningStatus.wifiScanInProgress,
      networks: [],
      error: null,
    ));

    _scanSub = _scanWifi().listen((networks) {
      emit(state.copyWith(
        status: ProvisioningStatus.wifiScanInProgress,
        networks: networks,
      ));
    }, onError: (e) {
      emit(state.copyWith(
        status: ProvisioningStatus.error,
        error: 'Wi-Fi scan failed: $e',
      ));
    }, onDone: () {
      // Scan completed, networks list is final.
      emit(state.copyWith(
        status: ProvisioningStatus.wifiScanDone,
      ));
    });
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

    await _connSub?.cancel();
    emit(state.copyWith(
      status: ProvisioningStatus.wifiConnecting,
      lastConnectStatus: null,
      error: null,
    ));

    _connSub = _connectWifi(
      ssid: network.ssid,
      password: password,
    ).listen((status) {
      emit(state.copyWith(
        lastConnectStatus: status,
        status: _mapConnectState(status),
      ));
    }, onError: (e) {
      emit(state.copyWith(
        status: ProvisioningStatus.error,
        error: 'Wi-Fi connect failed: $e',
      ));
    });
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
    await _connSub?.cancel();
    await _disconnectBle();
    return super.close();
  }
}
