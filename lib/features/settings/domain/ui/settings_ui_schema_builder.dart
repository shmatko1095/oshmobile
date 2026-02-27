import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';

/// Builds UI-facing settings schema from:
/// - contract JSON schemas (`settings.set` + `settings.patch`)
/// - optional model-level UI hints.
abstract interface class SettingsUiSchemaBuilder {
  SettingsUiSchema build({
    required Map<String, dynamic> setSchemaJson,
    required Map<String, dynamic> patchSchemaJson,
    Map<String, dynamic>? modelHintsJson,
  });
}
