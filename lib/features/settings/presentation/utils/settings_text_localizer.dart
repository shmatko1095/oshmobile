import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/generated/l10n.dart';

class SettingsTextLocalizer {
  const SettingsTextLocalizer();

  String groupTitle(BuildContext context, SettingsUiGroup group) {
    final fallback = _fallbackGroupTitle(group);
    return _lookup(context, key: group.id, fallback: fallback);
  }

  String fieldTitle(BuildContext context, SettingsUiField field) {
    final fallback = _fallbackFieldTitle(field);
    return _lookup(context, key: field.id, fallback: fallback);
  }

  String _lookup(
    BuildContext context, {
    required String key,
    required String fallback,
  }) {
    final normalizedFallback = _normalize(fallback) ?? '';
    final normalizedKey = _normalize(key);
    if (normalizedKey == null) return normalizedFallback;

    // Ensure localization delegate is resolved for this context.
    S.of(context);

    final localized = Intl.message(
      normalizedFallback,
      name: normalizedKey,
      desc: '',
      args: const [],
    );
    return _normalize(localized) ?? normalizedFallback;
  }

  String _fallbackGroupTitle(SettingsUiGroup group) {
    return _normalize(group.titleKey) ?? _normalize(group.id) ?? '';
  }

  String _fallbackFieldTitle(SettingsUiField field) {
    return _normalize(field.titleKey) ?? _normalize(field.path) ?? '';
  }

  String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }
}
