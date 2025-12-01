import 'package:oshmobile/features/ble_provisioning/domain/repositories/ble_provisioning_repository.dart';

class DisconnectBleDevice {
  final BleProvisioningRepository _repo;

  const DisconnectBleDevice(this._repo);

  Future<void> call() => _repo.disconnect();
}
