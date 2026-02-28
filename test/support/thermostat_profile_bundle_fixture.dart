import 'package:oshmobile/core/common/entities/device/known_device_models.dart';
import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';

DeviceProfileBundle createThermostatProfileBundle({
  String serial = 'TEST-SN',
  String modelId = t1aFlWzeModelId,
  Set<String> negotiatedSchemas = const <String>{
    'settings@1',
    'schedule@1',
    'telemetry@1',
    'sensors@1',
  },
}) {
  final bundle = DeviceProfileBundle.fromJson(
    <String, dynamic>{
      'bundle_schema_version': 1,
      'serial': serial,
      'model_id': modelId,
      'model_name': t1aFlWzeModelName,
      'profile_version': '2026-02-27',
      'model_profile': <String, dynamic>{
        'profile_schema_version': 1,
        'model_id': modelId,
        'model_name': t1aFlWzeModelName,
        'display_name': t1aFlWzeDisplayName,
        'profile_version': '2026-02-27',
        'integrations': <String, dynamic>{
          'osh': <String, dynamic>{
            'bootstrap': <String, dynamic>{
              'contracts_required': true,
              'legacy_fallback_allowed': false,
            },
            'domains': <String, dynamic>{
              'settings': <String, dynamic>{'required': true},
              'sensors': <String, dynamic>{'required': true},
              'schedule': <String, dynamic>{'required': true},
              'telemetry': <String, dynamic>{'required': true},
            },
            'widgets': <String, dynamic>{
              'heroTemperature': <String, dynamic>{
                'enabled': true,
                'control_ids': <String>[
                  'ambient_temperature',
                  'telemetry_climate_sensors',
                  'schedule_current_target_temp',
                  'schedule_next_target_temp',
                ],
              },
              'modeBar': <String, dynamic>{
                'enabled': true,
                'control_ids': <String>['schedule_current_target_temp'],
              },
              'heatingToggle': <String, dynamic>{
                'enabled': true,
                'control_ids': <String>['heater_enabled'],
              },
              'loadFactor24h': <String, dynamic>{
                'enabled': true,
                'control_ids': <String>['heating_activity_24h'],
              },
            },
            'controls': <String, dynamic>{
              'ambient_temperature': <String, dynamic>{
                'enabled': true,
                'widget_ids': <String>['heroTemperature'],
              },
              'ambient_humidity': <String, dynamic>{
                'enabled': true,
              },
              'telemetry_climate_sensors': <String, dynamic>{
                'enabled': true,
                'widget_ids': <String>['heroTemperature'],
              },
              'schedule_current_target_temp': <String, dynamic>{
                'enabled': true,
                'widget_ids': <String>['heroTemperature', 'modeBar'],
              },
              'schedule_next_target_temp': <String, dynamic>{
                'enabled': true,
                'widget_ids': <String>['heroTemperature'],
              },
              'heater_enabled': <String, dynamic>{
                'enabled': true,
                'widget_ids': <String>['heatingToggle'],
              },
              'heating_activity_24h': <String, dynamic>{
                'enabled': true,
                'widget_ids': <String>['loadFactor24h'],
              },
              'settings_display_active_brightness': <String, dynamic>{
                'enabled': true,
                'settings_group': 'display',
                'order': 10,
              },
              'settings_display_language': <String, dynamic>{
                'enabled': true,
                'settings_group': 'display',
                'order': 20,
              },
              'settings_control_max_floor_temp': <String, dynamic>{
                'enabled': true,
                'settings_group': 'control',
                'order': 10,
              },
            },
            'settings_groups': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'display',
                'title': 'Display',
                'order': <String>[
                  'settings_display_active_brightness',
                  'settings_display_language',
                ],
              },
              <String, dynamic>{
                'id': 'control',
                'title': 'Control',
                'order': <String>['settings_control_max_floor_temp'],
              },
            ],
            'schedule_modes': <String>['off', 'on', 'daily', 'weekly', 'range'],
          },
        },
      },
      'control_catalog': <String, dynamic>{
        'controls': <String, dynamic>{
          'ambient_temperature': <String, dynamic>{
            'title': 'Ambient temperature',
            'access': 'read',
          },
          'ambient_humidity': <String, dynamic>{
            'title': 'Ambient humidity',
            'access': 'read',
          },
          'telemetry_climate_sensors': <String, dynamic>{
            'title': 'Climate sensors',
            'access': 'read',
          },
          'schedule_current_target_temp': <String, dynamic>{
            'title': 'Current target temperature',
            'access': 'read',
          },
          'schedule_next_target_temp': <String, dynamic>{
            'title': 'Next target temperature',
            'access': 'read',
          },
          'heater_enabled': <String, dynamic>{
            'title': 'Heating',
            'access': 'read',
          },
          'heating_activity_24h': <String, dynamic>{
            'title': 'Heating activity (24h)',
            'access': 'read',
            'presentation': <String, dynamic>{'unit': '%'},
          },
          'settings_display_active_brightness': <String, dynamic>{
            'title': 'Active brightness',
            'access': 'read_write',
            'presentation': <String, dynamic>{'unit': '%'},
          },
          'settings_display_language': <String, dynamic>{
            'title': 'Language',
            'access': 'read_write',
          },
          'settings_control_max_floor_temp': <String, dynamic>{
            'title': 'Maximum floor temperature',
            'access': 'read_write',
            'presentation': <String, dynamic>{'unit': 'C'},
          },
        },
      },
      'bindings': <String, dynamic>{
        'controls': <String, dynamic>{
          'ambient_temperature': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'reference_sensor_field',
              'domain': 'telemetry',
              'schema': 'telemetry@1',
              'field': 'temp',
              'validField': 'temp_valid',
              'requires': <String>['telemetry@1', 'sensors@1'],
            },
          },
          'ambient_humidity': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'reference_sensor_field',
              'domain': 'telemetry',
              'schema': 'telemetry@1',
              'field': 'humidity',
              'validField': 'humidity_valid',
              'requires': <String>['telemetry@1', 'sensors@1'],
            },
          },
          'telemetry_climate_sensors': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'joined_climate_sensor_cards',
              'domain': 'telemetry',
              'schema': 'telemetry@1',
              'requires': <String>['telemetry@1', 'sensors@1'],
            },
          },
          'schedule_current_target_temp': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'schedule_current_target',
              'domain': 'schedule',
              'schema': 'schedule@1',
              'requires': <String>['schedule@1'],
            },
          },
          'schedule_next_target_temp': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'schedule_next_target',
              'domain': 'schedule',
              'schema': 'schedule@1',
              'requires': <String>['schedule@1'],
            },
          },
          'heater_enabled': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'state_snapshot',
              'domain': 'telemetry',
              'schema': 'telemetry@1',
              'path': 'heater_enabled',
              'requires': <String>['telemetry@1'],
            },
          },
          'heating_activity_24h': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'state_snapshot',
              'domain': 'telemetry',
              'schema': 'telemetry@1',
              'path': 'load_factor',
              'requires': <String>['telemetry@1'],
            },
          },
          'settings_display_active_brightness': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'state_snapshot',
              'domain': 'settings',
              'schema': 'settings@1',
              'path': 'display.activeBrightness',
              'requires': <String>['settings@1'],
            },
            'write': <String, dynamic>{
              'kind': 'patch_field',
              'domain': 'settings',
              'schema': 'settings@1',
              'method': 'settings.patch',
              'path': 'display.activeBrightness',
              'requires': <String>['settings@1'],
            },
          },
          'settings_display_language': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'state_snapshot',
              'domain': 'settings',
              'schema': 'settings@1',
              'path': 'display.language',
              'feature': 'display.language',
              'requires': <String>['settings@1'],
            },
            'write': <String, dynamic>{
              'kind': 'patch_field',
              'domain': 'settings',
              'schema': 'settings@1',
              'method': 'settings.patch',
              'path': 'display.language',
              'feature': 'display.language',
              'requires': <String>['settings@1'],
            },
          },
          'settings_control_max_floor_temp': <String, dynamic>{
            'read': <String, dynamic>{
              'kind': 'state_snapshot',
              'domain': 'settings',
              'schema': 'settings@1',
              'path': 'control.maxFloorTemp',
              'feature': 'control.maxFloorTemp',
              'requires': <String>['settings@1'],
            },
            'write': <String, dynamic>{
              'kind': 'patch_field',
              'domain': 'settings',
              'schema': 'settings@1',
              'method': 'settings.patch',
              'path': 'control.maxFloorTemp',
              'feature': 'control.maxFloorTemp',
              'requires': <String>['settings@1'],
            },
          },
        },
      },
    },
  );

  final readableDomains = <String>{};
  final patchableDomains = <String>{};
  final settableDomains = <String>{};
  for (final schema in negotiatedSchemas) {
    switch (schema) {
      case 'settings@1':
        readableDomains.add('settings');
        patchableDomains.add('settings');
        settableDomains.add('settings');
      case 'schedule@1':
        readableDomains.add('schedule');
        patchableDomains.add('schedule');
        settableDomains.add('schedule');
      case 'telemetry@1':
        readableDomains.add('telemetry');
      case 'sensors@1':
        readableDomains.add('sensors');
        patchableDomains.add('sensors');
        settableDomains.add('sensors');
    }
  }

  return bundle.copyWith(
    serial: serial,
    modelId: modelId,
    modelName: t1aFlWzeModelName,
    negotiatedSchemas: negotiatedSchemas,
    readableDomains: readableDomains,
    patchableDomains: patchableDomains,
    settableDomains: settableDomains,
    negotiatedFeaturesByDomain: <String, Set<String>>{
      'settings': const <String>{'display.language', 'control.maxFloorTemp'},
      'schedule': const <String>{'range-mode'},
      'sensors': const <String>{'rename', 'set_ref', 'set_temp_calibration', 'remove'},
    },
  );
}
