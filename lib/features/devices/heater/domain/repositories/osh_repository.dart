import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';

abstract interface class OshRepository {
  Future<Either<Failure, List<Device>>> assignDevice({
    required String uuid,
    required String sn,
    required String sc,
  });

  Future<Either<Failure, List<Device>>> unassignDevice({
    required String uuid,
    required String sn,
  });

  Future<Either<Failure, List<Device>>> getDeviceList({
    required String uuid,
  });
}
