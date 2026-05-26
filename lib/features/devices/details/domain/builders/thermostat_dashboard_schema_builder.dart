import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';

abstract interface class ThermostatDashboardSchemaBuilder {
  ThermostatDashboardSchema build({
    required DeviceConfigurationBundle bundle,
  });
}
