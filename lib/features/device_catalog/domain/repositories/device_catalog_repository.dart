import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';

abstract interface class DeviceCatalogRepository {
  Future<Either<Failure, void>> assignDevice({
    required String deviceSn,
    required String deviceSc,
  });

  Future<Either<Failure, List<Device>>> getDevices();
}
