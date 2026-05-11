import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
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

  void _emitIfOpen(BleProvisioningState next) {
    if (isClosed) return;
    emit(next);
  }

  Future<void> startNearbyCheck({
    required String serialNumber,
  }) async {
    final hasPerms = await _permissions.ensureBlePermissions();
    if (isClosed) return;

    if (!hasPerms) {
      await OshAnalytics.logEvent(
        OshAnalyticsEvents.bleNearbyCheckFailed,
        parameters: {'reason': 'permission_denied'},
      );
      _emitIfOpen(state.copyWith(
        status: ProvisioningStatus.permissionDenied,
        deviceNearby: null,
        error: 'BLE permissions not granted',
      ));
      return;
    }

    await _nearbySub?.cancel();
    if (isClosed) return;
    _nearbySub = null;

    _emitIfOpen(state.copyWith(
      status: ProvisioningStatus.searchingNearby,
      deviceNearby: null,
      error: null,
    ));

    _nearbySub = _observeDeviceNearby(serialNumber: serialNumber).listen(
      (isNearby) {
        _emitIfOpen(state.copyWith(
          status: ProvisioningStatus.searchingNearby,
          deviceNearby: isNearby,
          error: null,
        ));
      },
      onError: (e, _) {
        unawaited(
          OshAnalytics.logEvent(
            OshAnalyticsEvents.bleNearbyCheckFailed,
            parameters: {'reason': 'observe_failed'},
          ),
        );
        _emitIfOpen(state.copyWith(
          status: ProvisioningStatus.error,
          deviceNearby: null,
          error: 'Nearby check failed: $e',
        ));
      },
    );
  }

  Future<void> ensureBleDisconnected() async {
    await _scanSub?.cancel();
    _scanSub = null;
    await _wifiConnSub?.cancel();
    _wifiConnSub = null;

    try {
      await _disconnectBleDevice();
    } catch (_) {}
  }

  Future<void> connect({
    required String serialNumber,
    required String secureCode,
  }) async {
    await OshAnalytics.logEvent(OshAnalyticsEvents.bleProvisionStarted);
    if (isClosed) return;

    await _nearbySub?.cancel();
    _nearbySub = null;

    await ensureBleDisconnected();
    if (isClosed) return;

    final hasPerms = await _permissions.ensureBlePermissions();
    if (isClosed) return;
    if (!hasPerms) {
      await OshAnalytics.logEvent(
        OshAnalyticsEvents.bleConnectFailed,
        parameters: {'reason': 'permission_denied'},
      );
      _emitIfOpen(state.copyWith(
        status: ProvisioningStatus.permissionDenied,
        error: 'BLE permissions not granted',
      ));
      return;
    }

    _emitIfOpen(
        state.copyWith(status: ProvisioningStatus.connectingBle, error: null));

    try {
      await _connectBleDevice(
          serialNumber: serialNumber, secureCode: secureCode);
      await OshAnalytics.logEvent(OshAnalyticsEvents.bleConnectSucceeded);
      if (isClosed) return;
      _emitIfOpen(
          state.copyWith(status: ProvisioningStatus.wifiScanIdle, error: null));
      await refreshScan();
    } catch (e) {
      await OshAnalytics.logEvent(
        OshAnalyticsEvents.bleConnectFailed,
        parameters: {'reason': 'connect_failed'},
      );
      _emitIfOpen(state.copyWith(
          status: ProvisioningStatus.error,
          error: 'Failed to connect via BLE: $e'));
    }
  }

  Future<void> refreshScan() async {
    await _scanSub?.cancel();
    if (isClosed) return;
    _scanSub = null;

    _emitIfOpen(state.copyWith(
      status: ProvisioningStatus.wifiScanInProgress,
      networks: const [],
      error: null,
    ));

    _scanSub = _scanWifiNetworks().listen(
      (networks) {
        _emitIfOpen(state.copyWith(
            status: ProvisioningStatus.wifiScanInProgress, networks: networks));
      },
      onError: (e) {
        unawaited(
          OshAnalytics.logEvent(
            OshAnalyticsEvents.bleWifiScanFailed,
            parameters: {'reason': 'scan_failed'},
          ),
        );
        _emitIfOpen(state.copyWith(
            status: ProvisioningStatus.error, error: 'Wi-Fi scan failed: $e'));
      },
      onDone: () {
        _emitIfOpen(state.copyWith(status: ProvisioningStatus.wifiScanDone));
      },
    );
  }

  void selectNetwork(WifiNetwork network) {
    _emitIfOpen(state.copyWith(
      selectedNetwork: network,
      status: ProvisioningStatus.enterPassword,
      error: null,
    ));
  }

  Future<void> connectWifi(String password) async {
    final network = state.selectedNetwork;
    if (network == null) return;

    await _wifiConnSub?.cancel();
    if (isClosed) return;
    _wifiConnSub = null;

    _emitIfOpen(state.copyWith(
      status: ProvisioningStatus.wifiConnecting,
      lastConnectStatus: null,
      error: null,
    ));

    _wifiConnSub = _connectWifiNetwork(
      ssid: network.ssid,
      password: password,
    ).listen(
      (status) {
        if (status.state == WifiConnectState.success) {
          unawaited(
            OshAnalytics.logEvent(
              OshAnalyticsEvents.bleWifiConnectSucceeded,
              parameters: {'auth_type': network.auth.name},
            ),
          );
        } else if (status.state == WifiConnectState.failed) {
          unawaited(
            OshAnalytics.logEvent(
              OshAnalyticsEvents.bleWifiConnectFailed,
              parameters: {
                'stage': 'wifi_connect',
                'auth_type': network.auth.name,
              },
            ),
          );
        }
        _emitIfOpen(state.copyWith(
          lastConnectStatus: status,
          status: _mapConnectState(status),
        ));
      },
      onError: (e) {
        unawaited(
          OshAnalytics.logEvent(
            OshAnalyticsEvents.bleWifiConnectFailed,
            parameters: {
              'stage': 'wifi_connect',
              'auth_type': network.auth.name,
            },
          ),
        );
        _emitIfOpen(state.copyWith(
          status: ProvisioningStatus.error,
          error: 'Wi-Fi connect failed: $e',
        ));
      },
    );
  }

  void resetForNewFlow() {
    _emitIfOpen(const BleProvisioningState.initial());
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
        return state.status;
    }
  }

  @override
  Future<void> close() async {
    await _nearbySub?.cancel();
    _nearbySub = null;
    await ensureBleDisconnected();
    return super.close();
  }
}
