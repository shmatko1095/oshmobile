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
    final groupsById = <String, SettingsUiGroup>{};

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
        );
        orderedPaths.add(path);
      }

      if (orderedPaths.isEmpty) continue;
      groupsById[group.id] = SettingsUiGroup(
        id: group.id,
        titleKey: group.title.isEmpty ? _humanize(group.id) : group.title,
        order: List<String>.unmodifiable(orderedPaths),
      );
    }

    return SettingsUiSchema(
      fieldsByPath: Map<String, SettingsUiField>.unmodifiable(
        LinkedHashMap<String, SettingsUiField>.from(fieldsByPath),
      ),
      groupsById: Map<String, SettingsUiGroup>.unmodifiable(
        LinkedHashMap<String, SettingsUiGroup>.from(groupsById),
      ),
    );
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
