import 'package:oshmobile/core/contracts/device_contracts_models.dart';

abstract interface class DeviceContractsRepository {
  Future<DeviceContractsSnapshot> fetch({bool forceGet = false});

  Stream<DeviceContractsSnapshot> watch();
}
