import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/home/data/datasources/device_remote_data_source.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource dataSource;

  DeviceRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, Device>> get({
    required String serial,
  }) async {
    try {
      final result = await dataSource.get(serial: serial);
      return right(result);
    } on ServerException catch (e) {
      return left(Failure.fromServerException(e));
    } on Exception catch (e) {
      return left(Failure.unexpected(e.toString()));
    }
  }
}
