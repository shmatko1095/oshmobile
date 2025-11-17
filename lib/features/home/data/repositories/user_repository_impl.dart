import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/home/data/datasources/user_remote_data_source.dart';
import 'package:oshmobile/features/home/domain/entities/user.dart';
import 'package:oshmobile/features/home/domain/entities/user_device.dart';
import 'package:oshmobile/features/home/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource dataSource;

  UserRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> assignDevice({
    required String userId,
    required String deviceSn,
    required String deviceSc,
  }) async {
    try {
      await dataSource.assignDevice(
        userId: userId,
        deviceSn: deviceSn,
        deviceSc: deviceSc,
      );
      return right(null);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unassignDevice({
    required String userId,
    required String deviceId,
  }) async {
    try {
      await dataSource.unassignDevice(
        userId: userId,
        deviceId: deviceId,
      );
      return right(null);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserDevice>>> getDevices({
    required String userId,
  }) async {
    try {
      final result = await dataSource.getDevices(userId: userId);
      return right(result);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> get({
    required String userId,
  }) async {
    try {
      final result = await dataSource.get(userId: userId);
      return right(result);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
