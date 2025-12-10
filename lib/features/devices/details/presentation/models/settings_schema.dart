/// Meta-information for a single setting field.
///
/// This describes HOW to render and validate a concrete setting,
/// not its current value.
class SettingsFieldMeta {
  /// Canonical id, e.g. "display.activeBrightness".
  final String id;

  /// Group id this field belongs to, e.g. "display".
  final String groupId;

  /// Logical type: "int" | "double" | "bool" | "string" | "enum".
  final String type;

  /// Preferred widget: "slider" | "switch" | "text" | "select".
  final String widget;

  /// Optional numeric limits and step (for sliders).
  final num? min;
  final num? max;
  final num? step;

  /// Optional default value if device does not report one.
  final Object? defaultValue;

  /// Optional unit for display, e.g. "%", "s", "min".
  final String? unit;

  /// Optional localization (or plain) key for field title.
  final String? titleKey;

  /// For "enum" type: allowed values and optional label keys.
  final List<Object>? enumValues;
  final List<String>? enumLabelKeys;

  const SettingsFieldMeta({
    required this.id,
    required this.groupId,
    required this.type,
    required this.widget,
    this.min,
    this.max,
    this.step,
    this.defaultValue,
    this.unit,
    this.titleKey,
    this.enumValues,
    this.enumLabelKeys,
  });

  factory SettingsFieldMeta.fromJson(String id, Map<String, dynamic> json) {
    return SettingsFieldMeta(
      id: id,
      groupId: json['group'] as String? ?? '',
      type: json['type'] as String? ?? 'string',
      widget: json['widget'] as String? ?? 'text',
      min: json['min'] as num?,
      max: json['max'] as num?,
      step: json['step'] as num?,
      defaultValue: json['default'],
      unit: json['unit'] as String?,
      titleKey: json['title'] as String?,
      enumValues: (json['enumValues'] as List?)?.cast<Object>(),
      enumLabelKeys: (json['enumLabels'] as List?)?.cast<String>(),
    );
  }
}

/// Meta-information about a group/section in Settings screen.
class SettingsGroupMeta {
  final String id;
  final String? titleKey;

  /// Ordered list of field ids inside this group.
  final List<String> order;

  const SettingsGroupMeta({
    required this.id,
    required this.order,
    this.titleKey,
  });

  factory SettingsGroupMeta.fromJson(Map<String, dynamic> json) {
    return SettingsGroupMeta(
      id: json['id'] as String,
      titleKey: json['title'] as String?,
      order: (json['order'] as List? ?? const <String>[]).cast<String>(),
    );
  }
}

/// Full schema: groups + fields.
///
/// Stored inside DeviceConfig.ui_hints.settings.
class SettingsSchema {
  final Map<String, SettingsGroupMeta> groupsById;
  final Map<String, SettingsFieldMeta> fieldsById;

  const SettingsSchema({
    required this.groupsById,
    required this.fieldsById,
  });

  factory SettingsSchema.fromJson(Map<String, dynamic> json) {
    final groupsList = (json['groups'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((m) => SettingsGroupMeta.fromJson(m.cast<String, dynamic>()))
        .toList();

    final fieldsMapRaw = (json['fields'] as Map? ?? const <String, dynamic>{}).cast<String, dynamic>();

    final fieldsById = <String, SettingsFieldMeta>{};
    fieldsMapRaw.forEach((fieldId, value) {
      if (value is Map) {
        fieldsById[fieldId] = SettingsFieldMeta.fromJson(fieldId, value.cast<String, dynamic>());
      }
    });

    final groupsById = {
      for (final g in groupsList) g.id: g,
    };

    return SettingsSchema(
      groupsById: groupsById,
      fieldsById: fieldsById,
    );
  }

  /// All groups in arbitrary (but stable) order.
  Iterable<SettingsGroupMeta> get groups => groupsById.values;

  SettingsGroupMeta? group(String id) => groupsById[id];

  SettingsFieldMeta? field(String id) => fieldsById[id];

  /// Returns fields in group according to group's [order].
  Iterable<SettingsFieldMeta> fieldsInGroup(String groupId) sync* {
    final g = groupsById[groupId];
    if (g == null) return;
    for (final fid in g.order) {
      final f = fieldsById[fid];
      if (f != null) yield f;
    }
  }
}
