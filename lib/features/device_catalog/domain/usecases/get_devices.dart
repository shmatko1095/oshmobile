import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/device_catalog/domain/repositories/device_catalog_repository.dart';

class GetDevices implements UseCase<List<Device>, NoParams> {
  final DeviceCatalogRepository deviceCatalogRepository;

  GetDevices({
    required this.deviceCatalogRepository,
  });

  @override
  Future<Either<Failure, List<Device>>> call(NoParams params) async {
    return deviceCatalogRepository.getDevices();
  }
}
