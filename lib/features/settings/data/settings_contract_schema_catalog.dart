import 'package:oshmobile/core/contracts/contract_registry.dart';

/// In-app catalog of contract payload schemas used by mobile runtime.
///
/// First release supports only `settings@1`.
class SettingsContractSchemaCatalog {
  static Map<String, dynamic>? schemaForRoute(ContractRoute route) {
    final d = route.descriptor;
    if (d.schemaDomain != 'settings' || d.major != 1) return null;

    switch (route.operation) {
      case 'set':
        return settingsSetV1;
      case 'patch':
        return settingsPatchV1;
      case 'state':
        return settingsSetV1;
      default:
        return null;
    }
  }

  static const Map<String, dynamic> settingsSetV1 = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'required': <String>['display', 'update', 'time'],
    'properties': <String, dynamic>{
      'display': <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'required': <String>[
          'activeBrightness',
          'idleBrightness',
          'idleTime',
          'dimOnIdle',
          'language',
        ],
        'properties': <String, dynamic>{
          'activeBrightness': <String, dynamic>{
            'type': 'integer',
            'minimum': 10,
            'maximum': 100,
          },
          'idleBrightness': <String, dynamic>{
            'type': 'integer',
            'minimum': 10,
            'maximum': 100,
          },
          'idleTime': <String, dynamic>{
            'type': 'integer',
            'minimum': 0,
            'maximum': 60,
          },
          'dimOnIdle': <String, dynamic>{
            'type': 'boolean',
          },
          'language': <String, dynamic>{
            'type': 'string',
            'enum': <String>['en', 'uk'],
          },
        },
      },
      'update': <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'required': <String>[
          'autoUpdateEnabled',
          'updateAtMidnight',
          'checkIntervalMin',
        ],
        'properties': <String, dynamic>{
          'autoUpdateEnabled': <String, dynamic>{
            'type': 'boolean',
          },
          'updateAtMidnight': <String, dynamic>{
            'type': 'boolean',
          },
          'checkIntervalMin': <String, dynamic>{
            'type': 'integer',
            'minimum': 1,
            'maximum': 1440,
          },
        },
      },
      'time': <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'required': <String>['auto', 'timeZone'],
        'properties': <String, dynamic>{
          'auto': <String, dynamic>{
            'type': 'boolean',
          },
          'timeZone': <String, dynamic>{
            'type': 'integer',
            'minimum': -12,
            'maximum': 12,
          },
        },
      },
      'control': <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'required': <String>['model'],
        'properties': <String, dynamic>{
          'model': <String, dynamic>{
            'type': 'string',
            'enum': <String>['tpi', 'r2c'],
          },
          'maxFloorTemp': <String, dynamic>{
            'type': 'number',
            'minimum': 10,
            'maximum': 50,
          },
          'maxFloorTempLimitEnabled': <String, dynamic>{
            'type': 'boolean',
          },
          'maxFloorTempFailSafe': <String, dynamic>{
            'type': 'boolean',
          },
        },
      },
    },
  };

  static const Map<String, dynamic> settingsPatchV1 = <String, dynamic>{
    'type': 'object',
    'additionalProperties': false,
    'properties': <String, dynamic>{
      'display': <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'properties': <String, dynamic>{
          'activeBrightness': <String, dynamic>{
            'type': 'integer',
            'minimum': 10,
            'maximum': 100,
          },
          'idleBrightness': <String, dynamic>{
            'type': 'integer',
            'minimum': 10,
            'maximum': 100,
          },
          'idleTime': <String, dynamic>{
            'type': 'integer',
            'minimum': 0,
            'maximum': 60,
          },
          'dimOnIdle': <String, dynamic>{
            'type': 'boolean',
          },
          'language': <String, dynamic>{
            'type': 'string',
            'enum': <String>['en', 'uk'],
          },
        },
      },
      'update': <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'properties': <String, dynamic>{
          'autoUpdateEnabled': <String, dynamic>{
            'type': 'boolean',
          },
          'updateAtMidnight': <String, dynamic>{
            'type': 'boolean',
          },
          'checkIntervalMin': <String, dynamic>{
            'type': 'integer',
            'minimum': 1,
            'maximum': 1440,
          },
        },
      },
      'time': <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'properties': <String, dynamic>{
          'auto': <String, dynamic>{
            'type': 'boolean',
          },
          'timeZone': <String, dynamic>{
            'type': 'integer',
            'minimum': -12,
            'maximum': 12,
          },
        },
      },
      'control': <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'properties': <String, dynamic>{
          'model': <String, dynamic>{
            'type': 'string',
            'enum': <String>['tpi', 'r2c'],
          },
          'maxFloorTemp': <String, dynamic>{
            'type': 'number',
            'minimum': 10,
            'maximum': 50,
          },
          'maxFloorTempLimitEnabled': <String, dynamic>{
            'type': 'boolean',
          },
          'maxFloorTempFailSafe': <String, dynamic>{
            'type': 'boolean',
          },
        },
      },
    },
  };
}
