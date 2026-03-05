import 'package:oshmobile/core/common/entities/device/device.dart';

abstract interface class DeviceRemoteDataSource {
  Future<Device> get({
    required String serial,
  });

  Future<void> updateDeviceUserData({
    required String serial,
    required String alias,
    required String description,
  });
}
