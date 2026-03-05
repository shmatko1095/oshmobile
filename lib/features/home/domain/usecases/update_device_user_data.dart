import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';

class UpdateDeviceUserDataParams {
  final String serial;
  final String alias;
  final String description;

  UpdateDeviceUserDataParams({
    required this.serial,
    required this.alias,
    required this.description,
  });
}

class UpdateDeviceUserData
    implements UseCase<void, UpdateDeviceUserDataParams> {
  final DeviceRepository deviceRepository;

  UpdateDeviceUserData({required this.deviceRepository});

  @override
  Future<Either<Failure, void>> call(UpdateDeviceUserDataParams params) async {
    return deviceRepository.updateDeviceUserData(
      serial: params.serial,
      alias: params.alias,
      description: params.description,
    );
  }
}
