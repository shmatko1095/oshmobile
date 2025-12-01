import 'dart:async';

import 'package:oshmobile/features/ble_provisioning/domain/repositories/ble_provisioning_repository.dart';

/// Watch whether a BLE device with a given serial number is nearby.
class ObserveDeviceNearby {
  final BleProvisioningRepository _repo;

  const ObserveDeviceNearby(this._repo);

  Stream<bool> call({required String serialNumber}) => _repo.observeDeviceNearby(serialNumber: serialNumber);
}
