import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';

abstract interface class SettingsUiSchemaBuilder {
  SettingsUiSchema build({
    required DeviceProfileBundle bundle,
  });
}
