import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/presentation/utils/settings_text_localizer.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  const localizer = SettingsTextLocalizer();

  test('normalizes enum values deterministically', () {
    expect(
      SettingsTextLocalizer.normalizeEnumValue('R2C mode.v1'),
      'r2c_mode_v1',
    );
    expect(SettingsTextLocalizer.normalizeEnumValue('  ---  '), 'value');
  });

  testWidgets('resolves ARB translations for descriptions and enum copy', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const field = SettingsUiField(
      id: 'controlModel',
      path: 'control.model',
      section: 'control',
      key: 'model',
      type: SettingsUiFieldType.enumeration,
      widget: SettingsUiWidget.select,
      writable: true,
      groupId: 'control',
      titleKey: 'Control model',
      descriptionKey: 'Fallback control model description',
      enumValues: ['tpi', 'r2c', 'hysteresis'],
      enumOptions: {
        'tpi': SettingsUiEnumOption(
          value: 'tpi',
          titleKey: 'TPI fallback',
          descriptionKey: 'Fallback TPI description',
        ),
        'r2c': SettingsUiEnumOption(
          value: 'r2c',
          titleKey: 'R2C fallback',
          descriptionKey: 'Fallback R2C description',
        ),
        'hysteresis': SettingsUiEnumOption(
          value: 'hysteresis',
          titleKey: 'Hysteresis fallback',
          descriptionKey: 'Fallback hysteresis description',
        ),
      },
    );

    expect(
      localizer.fieldDescription(context, field),
      'Select how the thermostat regulates heating.',
    );
    expect(localizer.enumOptionTitle(context, field, 'tpi'), 'TPI');
    expect(
      localizer.enumOptionDescription(context, field, 'tpi'),
      'TPI changes relay ON time within a 10 min cycle to keep the reference temperature near the target.\nUsually better for smooth setpoint holding; relay switching is limited to at least 2 min per state.',
    );
    expect(
      localizer.enumOptionDescription(context, field, 'hysteresis'),
      'Hysteresis turns heating ON below target minus the hysteresis value and OFF at the target temperature.\nThis is simple direct ON/OFF control with relay switching limited to at least 2 min per state.',
    );
  });

  testWidgets('falls back to configuration text when ARB keys are missing', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const group = SettingsUiGroup(
      id: 'customGroup',
      titleKey: 'Custom group',
      order: ['custom.value'],
    );
    const field = SettingsUiField(
      id: 'customSetting',
      path: 'custom.value',
      section: 'custom',
      key: 'value',
      type: SettingsUiFieldType.enumeration,
      widget: SettingsUiWidget.select,
      writable: true,
      groupId: 'customGroup',
      titleKey: 'Custom setting',
      descriptionKey: 'Custom setting fallback description',
      enumValues: ['value.one'],
      enumOptions: {
        'value.one': SettingsUiEnumOption(
          value: 'value.one',
          titleKey: 'Value one',
          descriptionKey: 'Value one fallback description',
        ),
      },
    );

    expect(localizer.groupTitle(context, group), 'Custom group');
    expect(localizer.fieldTitle(context, field), 'Custom setting');
    expect(
      localizer.fieldDescription(context, field),
      'Custom setting fallback description',
    );
    expect(localizer.enumOptionTitle(context, field, 'value.one'), 'Value one');
    expect(
      localizer.enumOptionDescription(context, field, 'value.one'),
      'Value one fallback description',
    );
  });

  testWidgets('resolves boolean descriptions for the current value', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    const field = SettingsUiField(
      id: 'maxFloorTempFailSafe',
      path: 'control.maxFloorTempFailSafe',
      section: 'control',
      key: 'maxFloorTempFailSafe',
      type: SettingsUiFieldType.boolean,
      widget: SettingsUiWidget.toggle,
      writable: true,
      groupId: 'controlLimits',
      titleKey: 'Floor sensor fail-safe',
      descriptionKey: 'Fallback generic fail-safe description',
      booleanOptions: {
        true: SettingsUiBooleanOption(
          value: true,
          descriptionKey: 'Fallback true description',
        ),
        false: SettingsUiBooleanOption(
          value: false,
          descriptionKey: 'Fallback false description',
        ),
      },
    );

    expect(
      localizer.booleanOptionDescription(context, field, true),
      'Heating continues when floor reference sensor data is unavailable.',
    );
    expect(
      localizer.booleanOptionDescription(context, field, false),
      'Heating is turned off when floor reference sensor data is unavailable.',
    );
  });
}
