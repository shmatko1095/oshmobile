import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';

class UpdateDeviceUserDataParams {
  final String deviceId;
  final String alias;
  final String description;

  UpdateDeviceUserDataParams({
    required this.deviceId,
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
      deviceId: params.deviceId,
      alias: params.alias,
      description: params.description,
    );
  }
}
