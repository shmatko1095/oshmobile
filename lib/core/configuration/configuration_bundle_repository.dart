import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';

abstract interface class ConfigurationBundleRepository {
  Future<DeviceConfigurationBundle> fetchBundle({
    required String serial,
  });
}
