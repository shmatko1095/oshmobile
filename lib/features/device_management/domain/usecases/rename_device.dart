import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/device_management/domain/repositories/device_management_repository.dart';

class RenameDeviceParams {
  final String serial;
  final String alias;
  final String description;

  RenameDeviceParams({
    required this.serial,
    required this.alias,
    required this.description,
  });
}

class RenameDevice implements UseCase<void, RenameDeviceParams> {
  final DeviceManagementRepository deviceManagementRepository;

  RenameDevice({required this.deviceManagementRepository});

  @override
  Future<Either<Failure, void>> call(RenameDeviceParams params) async {
    return deviceManagementRepository.renameDevice(
      serial: params.serial,
      alias: params.alias,
      description: params.description,
    );
  }
}
