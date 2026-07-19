import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_payload_validator.dart';

void main() {
  const validator = TelemetryPayloadValidator(
    stateSchema: _telemetryStateSchema,
  );

  test('accepts legacy telemetry@1 temperature payload without setpoint flags',
      () {
    expect(
      validator.validateStatePayload(_telemetryPayload(targetTemp: 21.5)),
      isTrue,
    );
  });

  test('accepts current telemetry@1 payload without deprecated load_factor',
      () {
    final payload = _telemetryPayload(targetTemp: 21.5)..remove('load_factor');

    expect(validator.validateStatePayload(payload), isTrue);
  });

  test('accepts temperature, ON, and OFF telemetry@1 setpoints', () {
    expect(
      validator.validateStatePayload(
        _telemetryPayload(
          targetTemp: 21.5,
          setpointOn: false,
          setpointOff: false,
        ),
      ),
      isTrue,
    );
    expect(
      validator.validateStatePayload(
        _telemetryPayload(setpointOn: true, setpointOff: false),
      ),
      isTrue,
    );
    expect(
      validator.validateStatePayload(
        _telemetryPayload(setpointOn: false, setpointOff: true),
      ),
      isTrue,
    );
  });

  test('rejects incompatible telemetry@1 setpoint fields', () {
    expect(
      validator.validateStatePayload(
        _telemetryPayload(
          targetTemp: 21.5,
          setpointOn: true,
          setpointOff: false,
        ),
      ),
      isFalse,
    );
    expect(
      validator.validateStatePayload(
        _telemetryPayload(setpointOn: true, setpointOff: true),
      ),
      isFalse,
    );
  });
}

Map<String, dynamic> _telemetryPayload({
  double? targetTemp,
  bool? setpointOn,
  bool? setpointOff,
}) =>
    <String, dynamic>{
      'climate_sensors': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'outside',
          'temp_valid': true,
          'humidity_valid': false,
          'temp': 20.5,
        },
      ],
      'heater_enabled': false,
      'load_factor': 0,
      if (targetTemp != null) 'target_temp': targetTemp,
      if (setpointOn != null) 'setpoint_on': setpointOn,
      if (setpointOff != null) 'setpoint_off': setpointOff,
    };

const _telemetryStateSchema = <String, dynamic>{
  'type': 'object',
  'required': <String>[
    'climate_sensors',
    'heater_enabled',
  ],
  'properties': <String, dynamic>{
    'climate_sensors': <String, dynamic>{
      'type': 'array',
      'items': <String, dynamic>{
        'type': 'object',
        'required': <String>['id', 'temp_valid', 'humidity_valid'],
        'properties': <String, dynamic>{
          'id': <String, dynamic>{'type': 'string'},
          'temp_valid': <String, dynamic>{'type': 'boolean'},
          'temp_stale': <String, dynamic>{'type': 'boolean'},
          'humidity_valid': <String, dynamic>{'type': 'boolean'},
          'temp': <String, dynamic>{'type': 'number'},
          'humidity': <String, dynamic>{'type': 'number'},
        },
        'allOf': <Map<String, dynamic>>[
          <String, dynamic>{
            'if': <String, dynamic>{
              'anyOf': <Map<String, dynamic>>[
                <String, dynamic>{
                  'required': <String>['temp_valid'],
                  'properties': <String, dynamic>{
                    'temp_valid': <String, dynamic>{'const': true},
                  },
                },
                <String, dynamic>{
                  'required': <String>['temp_stale'],
                  'properties': <String, dynamic>{
                    'temp_stale': <String, dynamic>{'const': true},
                  },
                },
              ],
            },
            'then': <String, dynamic>{
              'required': <String>['temp'],
            },
            'else': <String, dynamic>{
              'not': <String, dynamic>{
                'required': <String>['temp'],
              },
            },
          },
          <String, dynamic>{
            'if': <String, dynamic>{
              'properties': <String, dynamic>{
                'humidity_valid': <String, dynamic>{'const': true},
              },
            },
            'then': <String, dynamic>{
              'required': <String>['humidity'],
            },
            'else': <String, dynamic>{
              'not': <String, dynamic>{
                'required': <String>['humidity'],
              },
            },
          },
        ],
      },
    },
    'heater_enabled': <String, dynamic>{'type': 'boolean'},
    'load_factor': <String, dynamic>{'type': 'integer'},
    'target_temp': <String, dynamic>{'type': 'number'},
    'setpoint_on': <String, dynamic>{'type': 'boolean'},
    'setpoint_off': <String, dynamic>{'type': 'boolean'},
  },
  'allOf': <Map<String, dynamic>>[
    <String, dynamic>{
      'if': <String, dynamic>{
        'required': <String>['setpoint_on'],
      },
      'then': <String, dynamic>{
        'required': <String>['setpoint_off'],
      },
    },
    <String, dynamic>{
      'if': <String, dynamic>{
        'required': <String>['setpoint_off'],
      },
      'then': <String, dynamic>{
        'required': <String>['setpoint_on'],
      },
    },
    <String, dynamic>{
      'if': <String, dynamic>{
        'properties': <String, dynamic>{
          'setpoint_on': <String, dynamic>{'const': true},
        },
        'required': <String>['setpoint_on'],
      },
      'then': <String, dynamic>{
        'properties': <String, dynamic>{
          'setpoint_off': <String, dynamic>{'const': false},
        },
        'not': <String, dynamic>{
          'required': <String>['target_temp'],
        },
      },
    },
    <String, dynamic>{
      'if': <String, dynamic>{
        'properties': <String, dynamic>{
          'setpoint_off': <String, dynamic>{'const': true},
        },
        'required': <String>['setpoint_off'],
      },
      'then': <String, dynamic>{
        'properties': <String, dynamic>{
          'setpoint_on': <String, dynamic>{'const': false},
        },
        'not': <String, dynamic>{
          'required': <String>['target_temp'],
        },
      },
    },
    <String, dynamic>{
      'if': <String, dynamic>{
        'properties': <String, dynamic>{
          'setpoint_on': <String, dynamic>{'const': false},
          'setpoint_off': <String, dynamic>{'const': false},
        },
        'required': <String>['setpoint_on', 'setpoint_off'],
      },
      'then': <String, dynamic>{
        'required': <String>['target_temp'],
      },
    },
  ],
};
