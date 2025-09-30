// import 'package:fpdart/fpdart.dart';
// import 'package:oshmobile/core/common/entities/device/device.dart';
// import 'package:oshmobile/core/error/failures.dart';
// import 'package:oshmobile/features/home/data/datasources/user_remote_data_source.dart';
// import 'package:oshmobile/features/home/domain/repositories/user_repository.dart';
//
// class OshRepositoryImpl implements OshRepository {
//   final OshRemoteDataSource oshRemoteDataSource;
//
//   OshRepositoryImpl({required this.oshRemoteDataSource});
//
//   @override
//   Future<Either<Failure, List<Device>>> assignDevice({
//     required String uuid,
//     required String sn,
//     required String sc,
//   }) async {
//     try {
//       final result = await oshRemoteDataSource.assignDevice(uuid: uuid, sn: sn, sc: sc);
//       return right(result);
//     } on Exception catch (e) {
//       return left(Failure.unexpected(e.toString()));
//     }
//   }
//
//   @override
//   Future<Either<Failure, List<Device>>> unassignDevice({
//     required String uuid,
//     required String sn,
//   }) async {
//     try {
//       final result = await oshRemoteDataSource.unassignDevice(uuid: uuid, sn: sn);
//       return right(result);
//     } on Exception catch (e) {
//       return left(Failure.unexpected(e.toString()));
//     }
//   }
//
//   @override
//   Future<Either<Failure, List<Device>>> getDeviceList({
//     required String uuid,
//   }) async {
//     try {
//       final result = await oshRemoteDataSource.getDeviceList(uuid: uuid);
//       return right(result);
//     } on Exception catch (e) {
//       return left(Failure.unexpected(e.toString()));
//     }
//   }
// }
