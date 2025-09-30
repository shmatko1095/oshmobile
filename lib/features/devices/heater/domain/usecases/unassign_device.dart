// import 'package:fpdart/fpdart.dart';
// import 'package:oshmobile/core/common/entities/device/device.dart';
// import 'package:oshmobile/core/error/failures.dart';
// import 'package:oshmobile/core/usecase/usecase.dart';
// import 'package:oshmobile/features/home/domain/repositories/user_repository.dart';
//
// class UnassignDeviceParams {
//   final String uuid;
//   final String sn;
//
//   UnassignDeviceParams({
//     required this.uuid,
//     required this.sn,
//   });
// }
//
// class UnassignDevice implements UseCase<List<Device>, UnassignDeviceParams> {
//   final OshRepository oshRepository;
//
//   UnassignDevice({required this.oshRepository});
//
//   @override
//   Future<Either<Failure, List<Device>>> call(
//       UnassignDeviceParams params) async {
//     return oshRepository.unassignDevice(uuid: params.uuid, sn: params.sn);
//   }
// }
