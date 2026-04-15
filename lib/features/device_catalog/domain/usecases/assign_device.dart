import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/core/usecase/usecase.dart';
import 'package:oshmobile/features/device_catalog/domain/repositories/device_catalog_repository.dart';

class AssignDeviceParams {
  final String sn;
  final String sc;

  AssignDeviceParams({
    required this.sn,
    required this.sc,
  });
}

class AssignDevice implements UseCase<void, AssignDeviceParams> {
  final DeviceCatalogRepository deviceCatalogRepository;

  AssignDevice({required this.deviceCatalogRepository});

  @override
  Future<Either<Failure, void>> call(AssignDeviceParams params) async {
    return deviceCatalogRepository.assignDevice(
      deviceSn: params.sn,
      deviceSc: params.sc,
    );
  }
}
