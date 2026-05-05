import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/device_catalog/data/datasources/device_catalog_remote_data_source.dart';
import 'package:oshmobile/features/device_catalog/domain/repositories/device_catalog_repository.dart';

class DeviceCatalogRepositoryImpl implements DeviceCatalogRepository {
  final DeviceCatalogRemoteDataSource dataSource;

  DeviceCatalogRepositoryImpl({required this.dataSource});

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
    } on ServerException catch (e) {
      return left(Failure.fromServerException(e));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Device>>> getDevices() async {
    try {
      final result = await dataSource.getDevices();
      return right(result);
    } on ServerException catch (e) {
      return left(Failure.fromServerException(e));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
