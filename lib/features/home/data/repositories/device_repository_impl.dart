import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/home/data/datasources/device_remote_data_source.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource dataSource;

  DeviceRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, void>> create({
    required String serialNumber,
    required String secureCode,
    required String password,
    required String modelId,
  }) async {
    try {
      await dataSource.create(
        serialNumber: serialNumber,
        secureCode: secureCode,
        password: password,
        modelId: modelId,
      );
      return right(null);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete({
    required String deviceId,
  }) async {
    try {
      await dataSource.delete(deviceId: deviceId);
      return right(null);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Device>> get({
    required String deviceId,
  }) async {
    try {
      final result = await dataSource.get(deviceId: deviceId);
      return right(result);
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
