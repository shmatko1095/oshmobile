import 'package:fpdart/fpdart.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/configuration/configuration_bundle_repository.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/error/failures.dart';
import 'package:oshmobile/features/home/domain/repositories/device_repository.dart';

class GetDeviceFull {
  final DeviceRepository deviceRepository;
  final ConfigurationBundleRepository configurationBundleRepository;
  final DeviceRuntimeContracts runtimeContracts;

  GetDeviceFull({
    required this.deviceRepository,
    required this.configurationBundleRepository,
    required this.runtimeContracts,
  });

  Future<
      ({
        Device device,
        DeviceConfigurationBundle bundle,
      })> call(String deviceSerial) async {
    final Either<Failure, Device> res = await deviceRepository.get(
      serial: deviceSerial,
    );

    return await res.fold(
      (f) => Future.error(f.message ?? 'Failed to load device'),
      (device) async {
        runtimeContracts.reset();

        final bundle = await configurationBundleRepository.fetchBundle(
          serial: device.sn,
        );
        final resolved = runtimeContracts.applyRuntimeBundle(bundle);

        if (resolved.missingContracts.isNotEmpty) {
          throw CompatibilityError(
            'Configuration references mqtt contracts missing in runtime bundle: ${resolved.missingContracts.join(', ')}.',
          );
        }
        if (resolved.unsupportedContracts.isNotEmpty) {
          throw UpdateAppRequired(
            'Update required. Unsupported mqtt contract references: ${resolved.unsupportedContracts.join(', ')}.',
          );
        }

        final hydratedBundle = bundle.copyWith(
          readableDomains: resolved.readableDomains,
          patchableDomains: resolved.patchableDomains,
        );

        return (
          device: device,
          bundle: hydratedBundle,
        );
      },
    );
  }
}

class UpdateAppRequired implements Exception {
  final String message;

  const UpdateAppRequired(this.message);

  @override
  String toString() => message;
}

class CompatibilityError implements Exception {
  final String message;

  const CompatibilityError(this.message);

  @override
  String toString() => message;
}
