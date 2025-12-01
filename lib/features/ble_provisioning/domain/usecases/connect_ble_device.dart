import 'package:oshmobile/features/ble_provisioning/domain/repositories/ble_provisioning_repository.dart';

/// Establish BLE session with the device that has given serial number.
class ConnectBleDevice {
  final BleProvisioningRepository _repo;

  const ConnectBleDevice(this._repo);

  Future<void> call({
    required String serialNumber,
    required String secureCode,
  }) {
    return _repo.connectToDevice(
      serialNumber: serialNumber,
      secureCode: secureCode,
    );
  }
}
