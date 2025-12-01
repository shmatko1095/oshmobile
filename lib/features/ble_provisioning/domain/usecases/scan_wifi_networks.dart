import 'dart:async';

import 'package:oshmobile/features/ble_provisioning/domain/entities/wifi_network.dart';
import 'package:oshmobile/features/ble_provisioning/domain/repositories/ble_provisioning_repository.dart';

class ScanWifiNetworks {
  final BleProvisioningRepository _repo;

  const ScanWifiNetworks(this._repo);

  Stream<List<WifiNetwork>> call() => _repo.scanWifiNetworks();
}
