import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema_builder.dart';

/// Default implementation that derives UI schema from contracts JSON schema
/// and merges optional model hints.
class JsonSchemaSettingsUiSchemaBuilder implements SettingsUiSchemaBuilder {
  const JsonSchemaSettingsUiSchemaBuilder();

  @override
  SettingsUiSchema build({
    required Map<String, dynamic> setSchemaJson,
    required Map<String, dynamic> patchSchemaJson,
    Map<String, dynamic>? modelHintsJson,
  }) {
    final setRequiredSections =
        _asStringSet(setSchemaJson['required']) ?? const <String>{};
    final patchRootProps =
        _asMap(patchSchemaJson['properties']) ?? const <String, dynamic>{};
    final setRootProps =
        _asMap(setSchemaJson['properties']) ?? const <String, dynamic>{};

    final rootSections = <String>{}
      ..addAll(setRootProps.keys)
      ..addAll(patchRootProps.keys);

    final modelFields =
        _asMap(modelHintsJson?['fields']) ?? const <String, dynamic>{};
    final modelGroupsList =
        _asList(modelHintsJson?['groups']) ?? const <dynamic>[];
    final modelGroupsById = <String, SettingsUiGroup>{};

    for (final item in modelGroupsList) {
      final g = _asMap(item);
      if (g == null) continue;
      final id = g['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final title = g['title']?.toString();
      final order = _asStringList(g['order']) ?? const <String>[];
      modelGroupsById[id] = SettingsUiGroup(
        id: id,
        titleKey: title ?? _humanize(id),
        order: List<String>.unmodifiable(order),
      );
    }

    final fieldsByPath = <String, SettingsUiField>{};
    final groupsById = <String, SettingsUiGroup>{};

    for (final section in rootSections) {
      final setSection = _asMap(setRootProps[section]);
      final patchSection = _asMap(patchRootProps[section]);
      final setSectionProps =
          _asMap(setSection?['properties']) ?? const <String, dynamic>{};
      final patchSectionProps =
          _asMap(patchSection?['properties']) ?? const <String, dynamic>{};
      final setSectionRequired =
          _asStringSet(setSection?['required']) ?? const <String>{};

      final keys = <String>{}
        ..addAll(setSectionProps.keys)
        ..addAll(patchSectionProps.keys);

      if (keys.isEmpty) continue;

      final defaultGroupId = section;
      groupsById.putIfAbsent(
        defaultGroupId,
        () =>
            modelGroupsById[defaultGroupId] ??
            SettingsUiGroup(
              id: defaultGroupId,
              titleKey: _humanize(section),
            ),
      );

      for (final key in keys) {
        final setField = _asMap(setSectionProps[key]);
        final patchField = _asMap(patchSectionProps[key]);
        final source = setField ?? patchField ?? const <String, dynamic>{};

        final path = '$section.$key';
        final modelField = _asMap(modelFields[path]);

        final type = _resolveType(source, modelField);
        final groupId = modelField?['group']?.toString() ?? defaultGroupId;
        final titleKey = modelField?['title']?.toString() ?? _humanize(key);
        final requiredInSet = setRequiredSections.contains(section) &&
            setSectionRequired.contains(key);
        final patchable = patchField != null;
        final writable = patchable;
        final widget = _resolveWidget(type, source, modelField);
        final min = _asNum(source['minimum'] ?? modelField?['min']);
        final max = _asNum(source['maximum'] ?? modelField?['max']);
        final step = _asNum(modelField?['step']);
        final unit = modelField?['unit']?.toString();
        final enumValues = _resolveEnumValues(source, modelField);

        fieldsByPath[path] = SettingsUiField(
          path: path,
          section: section,
          key: key,
          type: type,
          widget: widget,
          min: min,
          max: max,
          step: step,
          unit: unit,
          enumValues: enumValues,
          requiredInSet: requiredInSet,
          patchable: patchable,
          writable: writable,
          groupId: groupId,
          titleKey: titleKey,
        );

        groupsById.putIfAbsent(
          groupId,
          () =>
              modelGroupsById[groupId] ??
              SettingsUiGroup(
                id: groupId,
                titleKey: _humanize(groupId),
              ),
        );
      }
    }

    return SettingsUiSchema(
      fieldsByPath: Map<String, SettingsUiField>.unmodifiable(fieldsByPath),
      groupsById: Map<String, SettingsUiGroup>.unmodifiable(groupsById),
    );
  }

  SettingsUiFieldType _resolveType(
    Map<String, dynamic> schemaField,
    Map<String, dynamic>? modelField,
  ) {
    final enumRaw = schemaField['enum'];
    if (enumRaw is List && enumRaw.isNotEmpty) {
      return SettingsUiFieldType.enumeration;
    }

    final modelType = modelField?['type']?.toString();
    switch (modelType) {
      case 'int':
        return SettingsUiFieldType.integer;
      case 'double':
        return SettingsUiFieldType.number;
      case 'bool':
        return SettingsUiFieldType.boolean;
      case 'string':
        return SettingsUiFieldType.string;
      case 'enum':
        return SettingsUiFieldType.enumeration;
    }

    final schemaType = schemaField['type']?.toString();
    switch (schemaType) {
      case 'integer':
        return SettingsUiFieldType.integer;
      case 'number':
        return SettingsUiFieldType.number;
      case 'boolean':
        return SettingsUiFieldType.boolean;
      case 'string':
        return SettingsUiFieldType.string;
      default:
        return SettingsUiFieldType.unknown;
    }
  }

  SettingsUiWidget _resolveWidget(
    SettingsUiFieldType type,
    Map<String, dynamic> schemaField,
    Map<String, dynamic>? modelField,
  ) {
    final hinted = modelField?['widget']?.toString();
    switch (hinted) {
      case 'slider':
        return SettingsUiWidget.slider;
      case 'switch':
        return SettingsUiWidget.toggle;
      case 'select':
        return SettingsUiWidget.select;
      case 'text':
        return SettingsUiWidget.text;
    }

    switch (type) {
      case SettingsUiFieldType.boolean:
        return SettingsUiWidget.toggle;
      case SettingsUiFieldType.enumeration:
        return SettingsUiWidget.select;
      case SettingsUiFieldType.integer:
      case SettingsUiFieldType.number:
        final hasRange = schemaField.containsKey('minimum') ||
            schemaField.containsKey('maximum');
        return hasRange ? SettingsUiWidget.slider : SettingsUiWidget.text;
      case SettingsUiFieldType.string:
        return SettingsUiWidget.text;
      case SettingsUiFieldType.unknown:
        return SettingsUiWidget.unsupported;
    }
  }

  List<String>? _resolveEnumValues(
    Map<String, dynamic> schemaField,
    Map<String, dynamic>? modelField,
  ) {
    final modelEnum = _asStringList(modelField?['enumValues']);
    if (modelEnum != null && modelEnum.isNotEmpty) return modelEnum;

    final schemaEnum = _asList(schemaField['enum']);
    if (schemaEnum == null || schemaEnum.isEmpty) return null;
    return schemaEnum.map((e) => e.toString()).toList(growable: false);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (k, v) => MapEntry(k.toString(), v),
      );
    }
    return null;
  }

  List<dynamic>? _asList(dynamic value) {
    if (value is List) return value;
    return null;
  }

  List<String>? _asStringList(dynamic value) {
    final list = _asList(value);
    if (list == null) return null;
    return list.map((e) => e.toString()).toList(growable: false);
  }

  Set<String>? _asStringSet(dynamic value) {
    final list = _asStringList(value);
    if (list == null) return null;
    return list.toSet();
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    return null;
  }

  String _humanize(String value) {
    if (value.isEmpty) return value;
    final normalized = value.replaceAll(RegExp(r'[_\-.]+'), ' ');
    final spaced = normalized.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    final compact = spaced.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return value;
    return compact[0].toUpperCase() + compact.substring(1);
  }
}
