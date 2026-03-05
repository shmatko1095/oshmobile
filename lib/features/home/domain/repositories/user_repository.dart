import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';

abstract interface class UserRepository {
  Future<Either<Failure, void>> assignDevice({
    required String deviceSn,
    required String deviceSc,
  });

  Future<Either<Failure, void>> unassignDevice({
    required String serial,
  });

  Future<Either<Failure, List<Device>>> getDevices();
}
