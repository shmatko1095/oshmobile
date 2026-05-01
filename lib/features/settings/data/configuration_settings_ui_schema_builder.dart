import 'dart:collection';

import 'package:oshmobile/core/configuration/control_registry.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema_builder.dart';

class ConfigurationSettingsUiSchemaBuilder implements SettingsUiSchemaBuilder {
  const ConfigurationSettingsUiSchemaBuilder();

  @override
  SettingsUiSchema build({
    required DeviceConfigurationBundle bundle,
  }) {
    final registry = ControlRegistry(bundle);
    final fieldsByPath = <String, SettingsUiField>{};
    final draftGroupsById = <String, _SettingsUiGroupDraft>{};
    final orderedGroupIds = <String>[];

    for (final group in bundle.configuration.oshmobile.settingsGroups.values) {
      final orderedPaths = <String>[];
      for (final controlId in group.controlIds) {
        final control = bundle.configuration.oshmobile.controls[controlId];
        if (control == null ||
            control.ui == null ||
            !registry.isVisible(controlId)) {
          continue;
        }

        final path = control.write?.path ?? control.read?.path;
        if (path == null || path.isEmpty) continue;

        final ui = control.ui!;
        final type = _resolveType(ui);
        final widget = _resolveWidget(ui, type);
        final writable = registry.canWrite(controlId);

        fieldsByPath[path] = SettingsUiField(
          id: control.id,
          path: path,
          section: _sectionOf(path),
          key: _keyOf(path),
          type: type,
          widget: widget,
          min: ui.min,
          max: ui.max,
          step: ui.step,
          unit: _normalizeUnit(ui.unit),
          enumValues: ui.enumValues.isEmpty ? null : ui.enumValues,
          writable: writable,
          groupId: group.id,
          titleKey:
              control.title.isEmpty ? _humanize(control.id) : control.title,
          descriptionKey: _normalizeText(control.description),
          enumOptions: _buildEnumOptions(control, ui),
          booleanOptions: _buildBooleanOptions(ui),
        );
        orderedPaths.add(path);
      }

      draftGroupsById[group.id] = _SettingsUiGroupDraft(
        id: group.id,
        titleKey: group.title.isEmpty ? _humanize(group.id) : group.title,
        parentGroupId: _normalizeText(group.parentGroupId),
        presentation: _resolvePresentation(group.presentation),
        order: List<String>.unmodifiable(orderedPaths),
      );
      orderedGroupIds.add(group.id);
    }

    final rootGroupIds = <String>[];
    final childGroupIdsByParent = <String, List<String>>{};
    for (final groupId in orderedGroupIds) {
      final draft = draftGroupsById[groupId];
      if (draft == null) continue;

      final parentGroupId = draft.parentGroupId;
      if (parentGroupId == null ||
          !draftGroupsById.containsKey(parentGroupId)) {
        rootGroupIds.add(groupId);
        continue;
      }

      childGroupIdsByParent.putIfAbsent(parentGroupId, () => <String>[]);
      childGroupIdsByParent[parentGroupId]!.add(groupId);
    }

    final visibilityCache = <String, bool>{};
    bool isVisible(String groupId, Set<String> visiting) {
      final cached = visibilityCache[groupId];
      if (cached != null) {
        return cached;
      }

      final draft = draftGroupsById[groupId];
      if (draft == null) {
        return false;
      }

      if (!visiting.add(groupId)) {
        return false;
      }

      final childGroupIds = childGroupIdsByParent[groupId] ?? const <String>[];
      final hasVisibleChildren = childGroupIds.any(
        (childId) => isVisible(childId, visiting),
      );
      visiting.remove(groupId);

      final visible = draft.order.isNotEmpty || hasVisibleChildren;
      visibilityCache[groupId] = visible;
      return visible;
    }

    final visibleGroupsById = <String, SettingsUiGroup>{};
    for (final groupId in orderedGroupIds) {
      if (!isVisible(groupId, <String>{})) {
        continue;
      }

      final draft = draftGroupsById[groupId]!;
      final childGroupIds = (childGroupIdsByParent[groupId] ?? const <String>[])
          .where((childId) => isVisible(childId, <String>{}))
          .toList(growable: false);
      final hasChildren = childGroupIds.isNotEmpty;
      final presentation =
          hasChildren ? SettingsUiGroupPresentation.screen : draft.presentation;

      visibleGroupsById[groupId] = SettingsUiGroup(
        id: draft.id,
        titleKey: draft.titleKey,
        parentGroupId: draft.parentGroupId,
        presentation: presentation,
        order: draft.order,
        childGroupIds: List<String>.unmodifiable(childGroupIds),
      );
    }

    final visibleRootGroupIds = rootGroupIds
        .where((groupId) => visibleGroupsById.containsKey(groupId))
        .toList(growable: false);

    return SettingsUiSchema(
      fieldsByPath: Map<String, SettingsUiField>.unmodifiable(
        LinkedHashMap<String, SettingsUiField>.from(fieldsByPath),
      ),
      groupsById: Map<String, SettingsUiGroup>.unmodifiable(
        visibleGroupsById,
      ),
      rootGroupIds: List<String>.unmodifiable(visibleRootGroupIds),
    );
  }

  Map<String, SettingsUiEnumOption> _buildEnumOptions(
    ConfigurationControl control,
    ConfigurationControlUi ui,
  ) {
    if (ui.enumValues.isEmpty) {
      return const <String, SettingsUiEnumOption>{};
    }

    final options = <String, SettingsUiEnumOption>{};
    for (final value in ui.enumValues) {
      final metadata = ui.enumDisplay[value];
      options[value] = SettingsUiEnumOption(
        value: value,
        titleKey: _normalizeText(metadata?.title) ?? value,
        descriptionKey: _normalizeText(metadata?.description),
      );
    }
    return Map<String, SettingsUiEnumOption>.unmodifiable(options);
  }

  Map<bool, SettingsUiBooleanOption> _buildBooleanOptions(
    ConfigurationControlUi ui,
  ) {
    if (ui.booleanDisplay.isEmpty) {
      return const <bool, SettingsUiBooleanOption>{};
    }

    final options = <bool, SettingsUiBooleanOption>{};
    ui.booleanDisplay.forEach((value, metadata) {
      options[value] = SettingsUiBooleanOption(
        value: value,
        descriptionKey: _normalizeText(metadata.description),
      );
    });
    return Map<bool, SettingsUiBooleanOption>.unmodifiable(options);
  }

  SettingsUiFieldType _resolveType(ConfigurationControlUi ui) {
    switch (ui.fieldType) {
      case 'boolean':
        return SettingsUiFieldType.boolean;
      case 'enumeration':
        return SettingsUiFieldType.enumeration;
      case 'integer':
        return SettingsUiFieldType.integer;
      case 'number':
        return SettingsUiFieldType.number;
      case 'string':
        return SettingsUiFieldType.string;
      default:
        return SettingsUiFieldType.unknown;
    }
  }

  SettingsUiWidget _resolveWidget(
    ConfigurationControlUi ui,
    SettingsUiFieldType type,
  ) {
    switch (ui.widget) {
      case 'slider':
        return SettingsUiWidget.slider;
      case 'select':
        return SettingsUiWidget.select;
      case 'toggle':
        return SettingsUiWidget.toggle;
      case 'text':
        return SettingsUiWidget.text;
      case 'unsupported':
        return SettingsUiWidget.unsupported;
    }

    switch (type) {
      case SettingsUiFieldType.boolean:
        return SettingsUiWidget.toggle;
      case SettingsUiFieldType.enumeration:
        return SettingsUiWidget.select;
      case SettingsUiFieldType.integer:
      case SettingsUiFieldType.number:
        return ui.min != null && ui.max != null
            ? SettingsUiWidget.slider
            : SettingsUiWidget.text;
      case SettingsUiFieldType.string:
        return SettingsUiWidget.text;
      case SettingsUiFieldType.unknown:
        return SettingsUiWidget.unsupported;
    }
  }

  SettingsUiGroupPresentation _resolvePresentation(String value) {
    switch (value) {
      case 'screen':
        return SettingsUiGroupPresentation.screen;
      default:
        return SettingsUiGroupPresentation.inline;
    }
  }

  String _sectionOf(String path) {
    final index = path.indexOf('.');
    return index == -1 ? path : path.substring(0, index);
  }

  String _keyOf(String path) {
    final index = path.lastIndexOf('.');
    return index == -1 ? path : path.substring(index + 1);
  }

  String? _normalizeUnit(String? unit) {
    switch (unit) {
      case 'C':
        return '°C';
      default:
        return unit;
    }
  }

  String? _normalizeText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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

class _SettingsUiGroupDraft {
  final String id;
  final String titleKey;
  final String? parentGroupId;
  final SettingsUiGroupPresentation presentation;
  final List<String> order;

  const _SettingsUiGroupDraft({
    required this.id,
    required this.titleKey,
    required this.parentGroupId,
    required this.presentation,
    required this.order,
  });
}
