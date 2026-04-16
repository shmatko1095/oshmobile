import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/device_management/domain/models/device_assigned_user.dart';

abstract interface class DeviceManagementRepository {
  Future<Either<Failure, void>> renameDevice({
    required String serial,
    required String alias,
    required String description,
  });

  Future<Either<Failure, void>> removeDevice({
    required String serial,
  });

  Future<Either<Failure, List<DeviceAssignedUser>>> getDeviceUsers({
    required String serial,
  });
}
