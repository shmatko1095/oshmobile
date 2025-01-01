import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/home/data/datasources/remote_data_source.dart';
import 'package:oshmobile/features/home/domain/repositories/osh_repository.dart';

class OshRepositoryImpl implements OshRepository {
  final OshRemoteDataSource oshRemoteDataSource;

  OshRepositoryImpl({required this.oshRemoteDataSource});

  @override
  Future<Either<Failure, void>> assignDevice({
    required String uuid,
    required String sn,
    required String sc,
  }) async {
    try {
      await oshRemoteDataSource.assignDevice(uuid: uuid, sn: sn, sc: sc);
      return right(null);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unassignDevice({
    required String uuid,
    required String sn,
  }) async {
    try {
      await oshRemoteDataSource.unassignDevice(uuid: uuid, sn: sn);
      return right(null);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> getDeviceList({
    required String uuid,
  }) async {
    try {
      await oshRemoteDataSource.getDeviceList(uuid: uuid);
      return right(null);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
