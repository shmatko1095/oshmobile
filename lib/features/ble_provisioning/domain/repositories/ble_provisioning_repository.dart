import 'dart:async';

import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_connect_status.dart';
import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_network.dart';

/// BLE Wi-Fi provisioning contract.
/// Implementation keeps an active BLE connection and routes JSON messages
/// to/from the device according to the protocol.
abstract interface class BleProvisioningRepository {
  /// Connect to BLE device that matches [serialNumber] in manufacturer data
  /// and prepare session (MTU, notifications, crypto).
  Future<void> connectToDevice({
    required String serialNumber,
    required String secureCode,
    Duration timeout,
  });

  /// Disconnect from device and cleanup resources.
  Future<void> disconnect();

  /// Start Wi-Fi scan and stream aggregated list of networks.
  ///
  /// Each event contains the current accumulated list.
  /// The stream completes when the device sends `scan_done` or on error.
  Stream<List<WifiNetwork>> scanWifiNetworks({
    Duration? timeout,
  });

  /// Send Wi-Fi credentials and stream status updates until success/failed.
  ///
  /// The stream completes after final state (success/failed) or on error.
  Stream<WifiConnectStatus> connectToWifi({
    required String ssid,
    required String password,
    Duration? timeout,
  });

  Stream<bool> observeDeviceNearby({
    required String serialNumber,
  });
}
