import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/home/domain/repositories/user_repository.dart';

class GetUserDevices implements UseCase<List<Device>, NoParams> {
  final UserRepository userRepository;

  GetUserDevices({
    required this.userRepository,
  });

  @override
  Future<Either<Failure, List<Device>>> call(NoParams params) async {
    return userRepository.getDevices();
  }
}
