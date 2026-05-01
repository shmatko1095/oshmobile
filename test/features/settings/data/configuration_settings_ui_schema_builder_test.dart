import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';
import 'package:oshmobile/features/settings/data/configuration_settings_ui_schema_builder.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';

void main() {
  const builder = ConfigurationSettingsUiSchemaBuilder();

  test('builds nested groups, field order, and enum metadata', () {
    final bundle = _bundleFromConfiguration({
      'schema_version': 1,
      'integrations': {
        'oshmobile': {
          'layout': 'thermostat_basic',
          'domains': {
            'settings': {'contract_id': 'settings@1'},
          },
          'widgets': const [],
          'collections': const [],
          'settings_groups': [
            {
              'id': 'display',
              'title': 'Display',
              'control_ids': ['displayDimOnIdle'],
            },
            {
              'id': 'control',
              'title': 'Heating control',
              'presentation': 'screen',
              'control_ids': ['controlModel'],
            },
            {
              'id': 'controlLimits',
              'title': 'Floor protection',
              'parent_group_id': 'control',
              'presentation': 'screen',
              'control_ids': [
                'maxFloorTemperature',
                'maxFloorTempLimitEnabled',
                'maxFloorTempFailSafe',
              ],
            },
          ],
          'controls': [
            {
              'id': 'displayDimOnIdle',
              'title': 'Dim on idle',
              'read': {
                'kind': 'domain_path',
                'domain': 'settings',
                'path': 'display.dimOnIdle',
              },
              'write': {
                'kind': 'patch_field',
                'domain': 'settings',
                'path': 'display.dimOnIdle',
              },
              'ui': {
                'widget': 'toggle',
                'field_type': 'boolean',
              },
            },
            {
              'id': 'controlModel',
              'title': 'Control model',
              'description': 'Select how the thermostat regulates heating.',
              'read': {
                'kind': 'domain_path',
                'domain': 'settings',
                'path': 'control.model',
              },
              'write': {
                'kind': 'patch_field',
                'domain': 'settings',
                'path': 'control.model',
              },
              'ui': {
                'widget': 'select',
                'field_type': 'enumeration',
                'enum_values': ['tpi', 'r2c', 'hysteresis'],
                'enum_display': {
                  'tpi': {
                    'title': 'TPI',
                    'description': 'Advance compensation.',
                  },
                  'r2c': {
                    'title': 'R2C',
                    'description': 'Room reaction.',
                  },
                },
              },
            },
            {
              'id': 'maxFloorTemperature',
              'title': 'Max floor temperature',
              'description':
                  'When the floor reaches this temperature, heating will be turned off.',
              'read': {
                'kind': 'domain_path',
                'domain': 'settings',
                'path': 'control.maxFloorTemp',
              },
              'write': {
                'kind': 'patch_field',
                'domain': 'settings',
                'path': 'control.maxFloorTemp',
              },
              'ui': {
                'widget': 'slider',
                'field_type': 'number',
                'min': 10,
                'max': 50,
                'step': 0.5,
                'unit': 'C',
              },
            },
            {
              'id': 'maxFloorTempLimitEnabled',
              'title': 'Floor temperature limit',
              'read': {
                'kind': 'domain_path',
                'domain': 'settings',
                'path': 'control.maxFloorTempLimitEnabled',
              },
              'write': {
                'kind': 'patch_field',
                'domain': 'settings',
                'path': 'control.maxFloorTempLimitEnabled',
              },
              'ui': {
                'widget': 'toggle',
                'field_type': 'boolean',
              },
            },
            {
              'id': 'maxFloorTempFailSafe',
              'title': 'Floor sensor fail-safe',
              'description':
                  'Behavior when floor reference sensor data is unavailable.',
              'read': {
                'kind': 'domain_path',
                'domain': 'settings',
                'path': 'control.maxFloorTempFailSafe',
              },
              'write': {
                'kind': 'patch_field',
                'domain': 'settings',
                'path': 'control.maxFloorTempFailSafe',
              },
              'ui': {
                'widget': 'toggle',
                'field_type': 'boolean',
                'boolean_display': {
                  'true': {
                    'description':
                        'Heating continues when floor reference sensor data is unavailable.',
                  },
                  'false': {
                    'description':
                        'Heating is turned off when floor reference sensor data is unavailable.',
                  },
                },
              },
            },
          ],
        },
      },
    });

    final schema = builder.build(bundle: bundle);

    expect(schema.rootGroupIds, ['display', 'control']);

    final controlGroup = schema.group('control');
    expect(controlGroup, isNotNull);
    expect(controlGroup!.presentation, SettingsUiGroupPresentation.screen);
    expect(controlGroup.childGroupIds, ['controlLimits']);

    final limitsGroup = schema.group('controlLimits');
    expect(limitsGroup, isNotNull);
    expect(limitsGroup!.parentGroupId, 'control');
    expect(limitsGroup.presentation, SettingsUiGroupPresentation.screen);

    expect(
      schema.fieldsInGroup('control').map((field) => field.path).toList(),
      ['control.model'],
    );
    expect(
      schema.fieldsInGroup('controlLimits').map((field) => field.path).toList(),
      [
        'control.maxFloorTemp',
        'control.maxFloorTempLimitEnabled',
        'control.maxFloorTempFailSafe',
      ],
    );

    final controlField = schema.field('control.model');
    expect(controlField, isNotNull);
    expect(
      controlField!.descriptionKey,
      'Select how the thermostat regulates heating.',
    );
    expect(controlField.enumOptions['tpi']?.titleKey, 'TPI');
    expect(
      controlField.enumOptions['tpi']?.descriptionKey,
      'Advance compensation.',
    );
    expect(
      controlField.enumOptions['hysteresis']?.titleKey,
      'hysteresis',
    );

    final maxFloorTempField = schema.field('control.maxFloorTemp');
    expect(maxFloorTempField?.unit, '°C');

    final failSafeField = schema.field('control.maxFloorTempFailSafe');
    expect(
      failSafeField?.descriptionKey,
      'Behavior when floor reference sensor data is unavailable.',
    );
    expect(
      failSafeField?.booleanOptions[true]?.descriptionKey,
      'Heating continues when floor reference sensor data is unavailable.',
    );
    expect(
      failSafeField?.booleanOptions[false]?.descriptionKey,
      'Heating is turned off when floor reference sensor data is unavailable.',
    );
  });

  test('keeps screen groups visible when only their child group has fields',
      () {
    final bundle = _bundleFromConfiguration({
      'schema_version': 1,
      'integrations': {
        'oshmobile': {
          'layout': 'thermostat_basic',
          'domains': {
            'settings': {'contract_id': 'settings@1'},
          },
          'widgets': const [],
          'collections': const [],
          'settings_groups': [
            {
              'id': 'control',
              'title': 'Heating control',
              'presentation': 'screen',
              'control_ids': const [],
            },
            {
              'id': 'controlLimits',
              'title': 'Floor protection',
              'parent_group_id': 'control',
              'presentation': 'screen',
              'control_ids': ['maxFloorTemperature'],
            },
          ],
          'controls': [
            {
              'id': 'maxFloorTemperature',
              'title': 'Max floor temperature',
              'read': {
                'kind': 'domain_path',
                'domain': 'settings',
                'path': 'control.maxFloorTemp',
              },
              'ui': {
                'widget': 'slider',
                'field_type': 'number',
                'min': 10,
                'max': 50,
              },
            },
          ],
        },
      },
    });

    final schema = builder.build(bundle: bundle);

    expect(schema.rootGroupIds, ['control']);
    expect(schema.group('control')?.childGroupIds, ['controlLimits']);
    expect(schema.group('controlLimits'), isNotNull);
  });
}

DeviceConfigurationBundle _bundleFromConfiguration(Map<String, dynamic> json) {
  return DeviceConfigurationBundle(
    configurationId: 'cfg-1',
    modelId: 'model-1',
    revision: 1,
    status: 'approved',
    firmwareVersion: '0.41',
    runtimeContractsByDomain: const <String, RuntimeContractRecord>{},
    runtimeContractsById: const <String, RuntimeContractRecord>{},
    readableDomains: const <String>{'settings'},
    patchableDomains: const <String>{'settings'},
    configuration: ModelConfiguration.fromJson(json),
  );
}
