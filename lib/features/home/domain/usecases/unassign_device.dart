import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/home/domain/repositories/user_repository.dart';

class UnassignDeviceParams {
  final String userId;
  final String deviceId;

  UnassignDeviceParams({
    required this.userId,
    required this.deviceId,
  });
}

class UnassignDevice implements UseCase<void, UnassignDeviceParams> {
  final UserRepository userRepository;

  UnassignDevice({required this.userRepository});

  @override
  Future<Either<Failure, void>> call(UnassignDeviceParams params) async {
    return userRepository.unassignDevice(userId: params.userId, deviceId: params.deviceId);
  }
}
