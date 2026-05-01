import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/presentation/utils/settings_text_localizer.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_readonly_tile.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_select_tile.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_slider_tile.dart';
import 'package:oshmobile/features/settings/presentation/widgets/settings_switch_tile.dart';

class DeviceSettingsFieldTile extends StatelessWidget {
  final SettingsUiField field;
  final SettingsSnapshot snapshot;
  final bool showDivider;
  final SettingsTextLocalizer textLocalizer;

  const DeviceSettingsFieldTile({
    super.key,
    required this.field,
    required this.snapshot,
    required this.showDivider,
    this.textLocalizer = const SettingsTextLocalizer(),
  });

  @override
  Widget build(BuildContext context) {
    final facade = context.read<DeviceFacade>();
    final title = textLocalizer.fieldTitle(context, field);
    final subtitle = _fieldSubtitle(context);

    switch (field.widget) {
      case SettingsUiWidget.toggle:
        final value = snapshot.getValue<bool>(field.path) ?? false;
        return SettingsSwitchTile(
          title: title,
          subtitle: subtitle,
          value: value,
          onChanged: field.writable
              ? (v) => facade.settings.patch(field.path, v)
              : (_) {},
          showDivider: showDivider,
        );

      case SettingsUiWidget.slider:
        final raw = snapshot.getValue<num>(field.path) ?? field.min ?? 0;
        final value = raw.toDouble();
        final min = (field.min ?? 0).toDouble();
        final max = (field.max ?? (min + 100)).toDouble();
        final step = (field.step ?? 1).toDouble().abs();

        return SettingsSliderTile(
          title: title,
          subtitle: subtitle,
          value: value,
          min: min,
          max: max > min ? max : min + 1,
          step: step > 0 ? step : 1,
          unit: field.unit,
          onChanged: field.writable
              ? (newVal) {
                  final snapped = _snapToStep(min, max, step, newVal);
                  if (field.type == SettingsUiFieldType.integer) {
                    facade.settings.patch(field.path, snapped.round());
                  } else {
                    facade.settings.patch(field.path, snapped);
                  }
                }
              : (_) {},
          showDivider: showDivider,
        );

      case SettingsUiWidget.select:
        final options = field.enumValues ?? const <String>[];
        return SettingsSelectTile(
          title: title,
          subtitle: subtitle,
          options: options,
          value: snapshot.getValue<Object?>(field.path)?.toString(),
          showDivider: showDivider,
          onChanged: field.writable
              ? (v) => facade.settings.patch(field.path, v)
              : null,
          optionTitleBuilder: (value) =>
              textLocalizer.enumOptionTitle(context, field, value),
        );

      case SettingsUiWidget.text:
        final value = snapshot.getValue<Object?>(field.path);
        return SettingsReadonlyTile(
          title: title,
          subtitle: subtitle,
          value: value?.toString(),
          showDivider: showDivider,
        );

      case SettingsUiWidget.unsupported:
        return SettingsReadonlyTile(
          title: title,
          subtitle: subtitle,
          value: 'Unsupported',
          showDivider: showDivider,
        );
    }
  }

  String? _fieldSubtitle(BuildContext context) {
    if (field.type == SettingsUiFieldType.boolean) {
      final value = snapshot.getValue<bool>(field.path);
      if (value != null) {
        final booleanDescription =
            textLocalizer.booleanOptionDescription(context, field, value);
        if (booleanDescription != null) {
          return booleanDescription;
        }
      }
    }

    if (field.widget == SettingsUiWidget.select) {
      final value = snapshot.getValue<Object?>(field.path)?.toString();
      if (value != null) {
        final enumDescription =
            textLocalizer.enumOptionDescription(context, field, value);
        if (enumDescription != null) {
          return enumDescription;
        }
      }
    }

    return textLocalizer.fieldDescription(context, field);
  }

  double _snapToStep(double min, double max, double step, double value) {
    final safeStep = step <= 0 ? 1.0 : step;
    final clamped = value.clamp(min, max);
    final n = ((clamped - min) / safeStep).round();
    return (min + n * safeStep).clamp(min, max);
  }
}
