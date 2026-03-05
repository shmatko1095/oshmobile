import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/home/data/datasources/user_remote_data_source.dart';
import 'package:oshmobile/features/home/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource dataSource;

  UserRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> assignDevice({
    required String deviceSn,
    required String deviceSc,
  }) async {
    try {
      await dataSource.assignDevice(
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
    required String serial,
  }) async {
    try {
      await dataSource.unassignDevice(
        serial: serial,
      );
      return right(null);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Device>>> getDevices() async {
    try {
      final result = await dataSource.getDevices();
      return right(result);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
