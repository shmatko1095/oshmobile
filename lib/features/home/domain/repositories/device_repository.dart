import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';

abstract interface class DeviceRepository {
  Future<Either<Failure, void>> create({
    required String serialNumber,
    required String secureCode,
    required String password,
    required String modelId,
  });

  Future<Either<Failure, void>> delete({
    required String deviceId,
  });

  Future<Either<Failure, Device>> get({
    required String deviceId,
  });

  Future<Either<Failure, void>> updateDeviceUserData({
    required String deviceId,
    required String alias,
    required String description,
  });
}
