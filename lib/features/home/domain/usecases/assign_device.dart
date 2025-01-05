import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/home/domain/repositories/osh_repository.dart';

class AssignDeviceParams {
  final String uuid;
  final String sn;
  final String sc;

  AssignDeviceParams({
    required this.uuid,
    required this.sn,
    required this.sc,
  });
}

class AssignDevice implements UseCase<List<Device>, AssignDeviceParams> {
  final OshRepository oshRepository;

  AssignDevice({required this.oshRepository});

  @override
  Future<Either<Failure, List<Device>>> call(AssignDeviceParams params) async {
    return oshRepository.assignDevice(
      uuid: params.uuid,
      sn: params.sn,
      sc: params.sc,
    );
  }
}
