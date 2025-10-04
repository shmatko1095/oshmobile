import 'package:oshmobile/core/common/entities/device/device.dart';

abstract interface class DeviceRemoteDataSource {
  Future<void> create({
    required String serialNumber,
    required String secureCode,
    required String password,
    required String modelId,
  });

  Future<void> delete({
    required String deviceId,
  });

  Future<Device> get({
    required String deviceId,
  });

  Future<void> updateDeviceUserData({
    required String deviceId,
    required String alias,
    required String description,
  });
}
