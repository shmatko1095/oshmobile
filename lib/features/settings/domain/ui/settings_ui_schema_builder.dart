import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';

abstract interface class SettingsUiSchemaBuilder {
  SettingsUiSchema build({
    required DeviceConfigurationBundle bundle,
  });
}
