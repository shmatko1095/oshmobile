import 'package:oshmobile/features/devices/details/presentation/models/settings_schema.dart';

class DeviceConfig {
  final Set<String> capabilities;
  final Set<String> hidden;
  final List<String> order;

  /// Optional schema describing how to render Settings for this device.
  ///
  /// Expected JSON shape under `ui_hints.settings`:
  ///
  /// {
  ///   "groups": [
  ///     { "id": "display", "title": "Display", "order": ["display.activeBrightness", ...] },
  ///     { "id": "update",  "title": "Updates", "order": ["update.autoUpdateEnabled", ...] }
  ///   ],
  ///   "fields": {
  ///     "display.activeBrightness": {
  ///       "group": "display",
  ///       "type": "int",
  ///       "widget": "slider",
  ///       "min": 0,
  ///       "max": 100,
  ///       "step": 1,
  ///       "unit": "%"
  ///     },
  ///     ...
  ///   }
  /// }
  final SettingsSchema? settings;

  const DeviceConfig({
    this.capabilities = const {},
    this.hidden = const {},
    this.order = const [],
    this.settings,
  });

  factory DeviceConfig.fromJson(Map<String, dynamic>? j) {
    j = j ?? {};
    final caps = ((j['capabilities'] ?? const []) as List).cast<String>().toSet();
    final hints = (j['ui_hints'] as Map?) ?? const {};

    final hidden = ((hints['dashboard.hidden'] ?? const []) as List).cast<String>().toSet();
    final order = ((hints['dashboard.order'] ?? const []) as List).cast<String>();

    final settingsJson = (hints['settings'] as Map?)?.cast<String, dynamic>();
    final settings = settingsJson != null ? SettingsSchema.fromJson(settingsJson) : null;

    return DeviceConfig(
      capabilities: caps,
      hidden: hidden,
      order: order,
      settings: settings,
    );
  }

  bool has(String cap) => capabilities.contains(cap);

  bool visible(String id) => !hidden.contains(id);
}
