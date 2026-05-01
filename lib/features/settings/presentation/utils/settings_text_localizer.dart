import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/generated/l10n.dart';

class SettingsTextLocalizer {
  const SettingsTextLocalizer();

  String groupTitle(BuildContext context, SettingsUiGroup group) {
    return _lookup(
      context,
      key: group.id,
      fallback: _normalize(group.titleKey) ?? _normalize(group.id) ?? '',
    );
  }

  String fieldTitle(BuildContext context, SettingsUiField field) {
    return _lookup(
      context,
      key: field.id,
      fallback: _normalize(field.titleKey) ?? _normalize(field.path) ?? '',
    );
  }

  String? fieldDescription(BuildContext context, SettingsUiField field) {
    return _lookupOptional(
      context,
      key: '${field.id}_description',
      fallback: field.descriptionKey,
    );
  }

  String enumOptionTitle(
    BuildContext context,
    SettingsUiField field,
    String value,
  ) {
    final option = field.enumOptions[value];
    return _lookup(
      context,
      key: '${field.id}_${normalizeEnumValue(value)}_title',
      fallback: _normalize(option?.titleKey) ?? _normalize(value) ?? value,
    );
  }

  String? enumOptionDescription(
    BuildContext context,
    SettingsUiField field,
    String value,
  ) {
    final option = field.enumOptions[value];
    return _lookupOptional(
      context,
      key: '${field.id}_${normalizeEnumValue(value)}_description',
      fallback: option?.descriptionKey,
    );
  }

  String? booleanOptionDescription(
    BuildContext context,
    SettingsUiField field,
    bool value,
  ) {
    final option = field.booleanOptions[value];
    return _lookupOptional(
      context,
      key: '${field.id}_${value ? 'true' : 'false'}_description',
      fallback: option?.descriptionKey,
    );
  }

  static String normalizeEnumValue(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'value' : normalized;
  }

  String _lookup(
    BuildContext context, {
    required String key,
    required String fallback,
  }) {
    return _lookupOptional(
          context,
          key: key,
          fallback: fallback,
        ) ??
        '';
  }

  String? _lookupOptional(
    BuildContext context, {
    required String key,
    required String? fallback,
  }) {
    final normalizedFallback = _normalize(fallback);
    final normalizedKey = _normalize(key);
    if (normalizedKey == null) return normalizedFallback;

    S.of(context);

    final localized = Intl.message(
      normalizedFallback ?? '',
      name: normalizedKey,
      desc: '',
      args: const [],
    );
    return _normalize(localized) ?? normalizedFallback;
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
