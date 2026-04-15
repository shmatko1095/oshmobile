import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/device_management/domain/repositories/device_management_repository.dart';

class RemoveDeviceParams {
  final String serial;

  RemoveDeviceParams({
    required this.serial,
  });
}

class RemoveDevice implements UseCase<void, RemoveDeviceParams> {
  final DeviceManagementRepository deviceManagementRepository;

  RemoveDevice({required this.deviceManagementRepository});

  @override
  Future<Either<Failure, void>> call(RemoveDeviceParams params) async {
    return deviceManagementRepository.removeDevice(serial: params.serial);
  }
}
