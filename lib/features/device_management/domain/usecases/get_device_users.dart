import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/device_management/domain/models/device_assigned_user.dart';
import 'package:oshmobile/features/device_management/domain/repositories/device_management_repository.dart';

class GetDeviceUsersParams {
  final String serial;

  GetDeviceUsersParams({
    required this.serial,
  });
}

class GetDeviceUsers
    implements UseCase<List<DeviceAssignedUser>, GetDeviceUsersParams> {
  final DeviceManagementRepository deviceManagementRepository;

  GetDeviceUsers({
    required this.deviceManagementRepository,
  });

  @override
  Future<Either<Failure, List<DeviceAssignedUser>>> call(
    GetDeviceUsersParams params,
  ) async {
    return deviceManagementRepository.getDeviceUsers(serial: params.serial);
  }
}
