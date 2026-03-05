import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/home/domain/repositories/user_repository.dart';

class AssignDeviceParams {
  final String sn;
  final String sc;

  AssignDeviceParams({
    required this.sn,
    required this.sc,
  });
}

class AssignDevice implements UseCase<void, AssignDeviceParams> {
  final UserRepository userRepository;

  AssignDevice({required this.userRepository});

  @override
  Future<Either<Failure, void>> call(AssignDeviceParams params) async {
    return userRepository.assignDevice(
      deviceSn: params.sn,
      deviceSc: params.sc,
    );
  }
}
