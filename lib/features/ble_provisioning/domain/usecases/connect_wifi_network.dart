import 'dart:async';

import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_connect_status.dart';
import 'package:oshmobile/features/ble_provisioning/domain/repositories/ble_provisioning_repository.dart';

class ConnectWifiNetwork {
  final BleProvisioningRepository _repo;

  const ConnectWifiNetwork(this._repo);

  Stream<WifiConnectStatus> call({
    required String ssid,
    required String password,
  }) {
    return _repo.connectToWifi(ssid: ssid, password: password);
  }
}
