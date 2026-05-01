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

enum SettingsUiGroupPresentation {
  inline,
  screen,
}

@immutable
class SettingsUiEnumOption {
  final String value;
  final String? titleKey;
  final String? descriptionKey;

  const SettingsUiEnumOption({
    required this.value,
    this.titleKey,
    this.descriptionKey,
  });
}

@immutable
class SettingsUiBooleanOption {
  final bool value;
  final String? descriptionKey;

  const SettingsUiBooleanOption({
    required this.value,
    this.descriptionKey,
  });
}

@immutable
class SettingsUiField {
  final String id;
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

  final bool writable;

  final String groupId;
  final String? titleKey;
  final String? descriptionKey;
  final Map<String, SettingsUiEnumOption> enumOptions;
  final Map<bool, SettingsUiBooleanOption> booleanOptions;

  const SettingsUiField({
    required this.id,
    required this.path,
    required this.section,
    required this.key,
    required this.type,
    required this.widget,
    required this.writable,
    required this.groupId,
    this.titleKey,
    this.descriptionKey,
    this.min,
    this.max,
    this.step,
    this.unit,
    this.enumValues,
    this.enumOptions = const <String, SettingsUiEnumOption>{},
    this.booleanOptions = const <bool, SettingsUiBooleanOption>{},
  });
}

@immutable
class SettingsUiGroup {
  final String id;
  final String? titleKey;
  final String? parentGroupId;
  final SettingsUiGroupPresentation presentation;
  final List<String> order;
  final List<String> childGroupIds;

  const SettingsUiGroup({
    required this.id,
    this.titleKey,
    this.parentGroupId,
    this.presentation = SettingsUiGroupPresentation.inline,
    this.order = const <String>[],
    this.childGroupIds = const <String>[],
  });
}

@immutable
class SettingsUiSchema {
  final Map<String, SettingsUiField> fieldsByPath;
  final Map<String, SettingsUiGroup> groupsById;
  final List<String> rootGroupIds;

  const SettingsUiSchema({
    required this.fieldsByPath,
    required this.groupsById,
    required this.rootGroupIds,
  });

  Iterable<SettingsUiGroup> get groups => groupsById.values;

  Iterable<SettingsUiGroup> get rootGroups sync* {
    for (final id in rootGroupIds) {
      final group = groupsById[id];
      if (group != null) {
        yield group;
      }
    }
  }

  bool get isEmpty => rootGroupIds.isEmpty && groupsById.isEmpty;

  SettingsUiField? field(String path) => fieldsByPath[path];

  SettingsUiGroup? group(String id) => groupsById[id];

  Iterable<SettingsUiGroup> childGroupsOf(String groupId) sync* {
    final group = groupsById[groupId];
    if (group == null) return;

    for (final childId in group.childGroupIds) {
      final child = groupsById[childId];
      if (child != null) {
        yield child;
      }
    }
  }

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
