import 'package:oshmobile/core/common/entities/device/device.dart';

abstract interface class DeviceCatalogRemoteDataSource {
  Future<void> assignDevice({
    required String deviceSn,
    required String deviceSc,
  });

  Future<List<Device>> getDevices();
}
