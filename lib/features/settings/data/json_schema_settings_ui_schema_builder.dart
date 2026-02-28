import 'dart:collection';

import 'package:oshmobile/core/profile/control_binding_registry.dart';
import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema_builder.dart';

class ProfileBundleSettingsUiSchemaBuilder implements SettingsUiSchemaBuilder {
  const ProfileBundleSettingsUiSchemaBuilder();

  @override
  SettingsUiSchema build({
    required DeviceProfileBundle bundle,
  }) {
    final registry = ControlBindingRegistry(bundle);
    final fieldsByPath = <String, SettingsUiField>{};
    final groupsById = <String, SettingsUiGroup>{};
    final controls = bundle.modelProfile.osh.controls;

    for (final group in bundle.modelProfile.osh.settingsGroups) {
      final groupControls = _controlsForGroup(
        bundle: bundle,
        groupId: group.id,
      );
      if (groupControls.isEmpty) continue;

      final orderedPaths = <String>[];
      for (final controlId in groupControls) {
        final control = controls[controlId];
        final entry = bundle.controlCatalog[controlId];
        final binding = bundle.bindings[controlId];
        if (control == null ||
            entry == null ||
            binding == null ||
            !control.enabled ||
            !registry.isVisible(controlId)) {
          continue;
        }

        final path = binding.write?.path ?? binding.read?.path;
        if (path == null || path.isEmpty) continue;

        final hint = _uiHints[controlId];
        final type = _resolveType(controlId);
        final widget = _resolveWidget(type, hint);
        final writable = registry.canWrite(controlId) &&
            (binding.write?.kind == 'patch_field' ||
                binding.write?.kind == 'state_patch_field');

        fieldsByPath[path] = SettingsUiField(
          path: path,
          section: _sectionOf(path),
          key: _keyOf(path),
          type: type,
          widget: widget,
          min: hint?.min,
          max: hint?.max,
          step: hint?.step,
          unit: _normalizeUnit(entry.unit),
          enumValues: hint?.enumValues,
          requiredInSet: false,
          patchable: writable,
          writable: writable,
          groupId: group.id,
          titleKey: entry.title.isEmpty ? _humanize(controlId) : entry.title,
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

  List<String> _controlsForGroup({
    required DeviceProfileBundle bundle,
    required String groupId,
  }) {
    final ordered = <String>[];
    final seen = <String>{};
    final controls = bundle.modelProfile.osh.controls;

    void push(String controlId) {
      if (!seen.add(controlId)) return;
      final control = controls[controlId];
      if (control == null || !control.enabled) return;
      if (control.settingsGroup != groupId) return;
      ordered.add(controlId);
    }

    final groups = bundle.modelProfile.osh.settingsGroups;
    var groupOrder = const <String>[];
    for (final group in groups) {
      if (group.id == groupId) {
        groupOrder = group.order;
        break;
      }
    }
    for (final controlId in groupOrder) {
      push(controlId);
    }

    final extra = controls.entries
        .where((entry) =>
            entry.value.enabled && entry.value.settingsGroup == groupId)
        .toList(growable: false)
      ..sort((a, b) {
        final ao = a.value.order ?? 1 << 30;
        final bo = b.value.order ?? 1 << 30;
        final byOrder = ao.compareTo(bo);
        if (byOrder != 0) return byOrder;
        return a.key.compareTo(b.key);
      });
    for (final entry in extra) {
      push(entry.key);
    }

    return ordered;
  }

  SettingsUiFieldType _resolveType(String controlId) {
    return _uiHints[controlId]?.type ?? SettingsUiFieldType.unknown;
  }

  SettingsUiWidget _resolveWidget(
    SettingsUiFieldType type,
    _SettingsUiHint? hint,
  ) {
    if (hint?.widget != null) {
      return hint!.widget!;
    }

    switch (type) {
      case SettingsUiFieldType.boolean:
        return SettingsUiWidget.toggle;
      case SettingsUiFieldType.enumeration:
        return SettingsUiWidget.select;
      case SettingsUiFieldType.integer:
      case SettingsUiFieldType.number:
        return hint?.min != null && hint?.max != null
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

class _SettingsUiHint {
  final SettingsUiWidget? widget;
  final SettingsUiFieldType? type;
  final num? min;
  final num? max;
  final num? step;
  final List<String>? enumValues;

  const _SettingsUiHint({
    this.widget,
    this.type,
    this.min,
    this.max,
    this.step,
    this.enumValues,
  });
}

const Map<String, _SettingsUiHint> _uiHints = <String, _SettingsUiHint>{
  'settings_display_active_brightness': _SettingsUiHint(
    widget: SettingsUiWidget.slider,
    type: SettingsUiFieldType.integer,
    min: 10,
    max: 100,
    step: 1,
  ),
  'settings_display_idle_brightness': _SettingsUiHint(
    widget: SettingsUiWidget.slider,
    type: SettingsUiFieldType.integer,
    min: 10,
    max: 100,
    step: 1,
  ),
  'settings_display_idle_time': _SettingsUiHint(
    widget: SettingsUiWidget.slider,
    type: SettingsUiFieldType.integer,
    min: 0,
    max: 60,
    step: 1,
  ),
  'settings_display_language': _SettingsUiHint(
    widget: SettingsUiWidget.select,
    type: SettingsUiFieldType.enumeration,
    enumValues: <String>['en', 'uk'],
  ),
  'settings_update_check_interval_min': _SettingsUiHint(
    widget: SettingsUiWidget.slider,
    type: SettingsUiFieldType.integer,
    min: 1,
    max: 1440,
    step: 1,
  ),
  'settings_time_time_zone': _SettingsUiHint(
    widget: SettingsUiWidget.slider,
    type: SettingsUiFieldType.integer,
    min: -12,
    max: 12,
    step: 1,
  ),
  'settings_control_model': _SettingsUiHint(
    widget: SettingsUiWidget.select,
    type: SettingsUiFieldType.enumeration,
    enumValues: <String>['tpi', 'r2c'],
  ),
  'settings_control_max_floor_temp': _SettingsUiHint(
    widget: SettingsUiWidget.slider,
    type: SettingsUiFieldType.number,
    min: 10,
    max: 50,
    step: 0.5,
  ),
};
