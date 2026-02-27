import 'package:meta/meta.dart';

enum SettingsUiFieldType {
  integer,
  number,
  boolean,
  string,
  enumeration,
  unknown,
}

enum SettingsUiWidget {
  slider,
  toggle,
  select,
  text,
  unsupported,
}

@immutable
class SettingsUiField {
  final String path;
  final String section;
  final String key;

  final SettingsUiFieldType type;
  final SettingsUiWidget widget;

  final num? min;
  final num? max;
  final num? step;
  final String? unit;
  final List<String>? enumValues;

  final bool requiredInSet;
  final bool patchable;
  final bool writable;

  final String groupId;
  final String? titleKey;

  const SettingsUiField({
    required this.path,
    required this.section,
    required this.key,
    required this.type,
    required this.widget,
    required this.requiredInSet,
    required this.patchable,
    required this.writable,
    required this.groupId,
    this.titleKey,
    this.min,
    this.max,
    this.step,
    this.unit,
    this.enumValues,
  });
}

@immutable
class SettingsUiGroup {
  final String id;
  final String? titleKey;
  final List<String> order;

  const SettingsUiGroup({
    required this.id,
    this.titleKey,
    this.order = const <String>[],
  });
}

@immutable
class SettingsUiSchema {
  final Map<String, SettingsUiField> fieldsByPath;
  final Map<String, SettingsUiGroup> groupsById;

  const SettingsUiSchema({
    required this.fieldsByPath,
    required this.groupsById,
  });

  Iterable<SettingsUiGroup> get groups => groupsById.values;

  SettingsUiField? field(String path) => fieldsByPath[path];

  SettingsUiGroup? group(String id) => groupsById[id];

  Iterable<SettingsUiField> fieldsInGroup(String groupId) sync* {
    final g = groupsById[groupId];
    if (g == null) return;

    final emitted = <String>{};
    for (final path in g.order) {
      final f = fieldsByPath[path];
      if (f == null) continue;
      emitted.add(path);
      yield f;
    }

    for (final f in fieldsByPath.values) {
      if (f.groupId != groupId) continue;
      if (emitted.contains(f.path)) continue;
      yield f;
    }
  }
}
