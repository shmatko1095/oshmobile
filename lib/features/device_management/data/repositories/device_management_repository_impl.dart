import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/device_management/data/datasources/device_management_remote_data_source.dart';
import 'package:oshmobile/features/device_management/domain/models/device_assigned_user.dart';
import 'package:oshmobile/features/device_management/domain/repositories/device_management_repository.dart';

class DeviceManagementRepositoryImpl implements DeviceManagementRepository {
  final DeviceManagementRemoteDataSource dataSource;

  DeviceManagementRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> removeDevice({
    required String serial,
  }) async {
    try {
      await dataSource.removeDevice(serial: serial);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure.fromServerException(e));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DeviceAssignedUser>>> getDeviceUsers({
    required String serial,
  }) async {
    try {
      final result = await dataSource.getDeviceUsers(serial: serial);
      return right(result);
    } on ServerException catch (e) {
      return left(Failure.fromServerException(e));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> renameDevice({
    required String serial,
    required String alias,
    required String description,
  }) async {
    try {
      await dataSource.renameDevice(
        serial: serial,
        alias: alias,
        description: description,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure.fromServerException(e));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
