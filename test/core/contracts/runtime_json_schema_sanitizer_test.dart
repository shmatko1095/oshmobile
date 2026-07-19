import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/contracts/runtime_json_schema_sanitizer.dart';

void main() {
  test('drops one invalid field while preserving sibling telemetry values', () {
    final issues = <String>[];
    final sanitized = RuntimeJsonSchemaSanitizer.sanitize(
      value: <String, dynamic>{
        'heater_enabled': 'ON',
        'target_temp': 21.5,
        'power_meter': <String, dynamic>{
          'voltage_v': '230.0',
          'current_a': 1.25,
          'future_value': <String, dynamic>{'kept': true},
        },
      },
      schema: _schema,
      onIssue: (path, reason) => issues.add('$path:$reason'),
    ) as Map<String, dynamic>;
    final powerMeter = sanitized['power_meter'] as Map<String, dynamic>;

    expect(sanitized, isNot(contains('heater_enabled')));
    expect(sanitized['target_temp'], 21.5);
    expect(powerMeter, isNot(contains('voltage_v')));
    expect(powerMeter['current_a'], 1.25);
    expect(powerMeter['future_value'], <String, dynamic>{'kept': true});
    expect(issues, contains('heater_enabled:expected_boolean'));
    expect(issues, contains('power_meter.voltage_v:expected_number'));
  });

  test('drops only malformed array items and fields', () {
    final issues = <String>[];
    final sanitized = RuntimeJsonSchemaSanitizer.sanitize(
      value: <String, dynamic>{
        'climate_sensors': <dynamic>[
          <String, dynamic>{'id': 'air', 'temp': 'bad'},
          'not-an-object',
          <String, dynamic>{'id': 'floor', 'temp': 27.5},
        ],
      },
      schema: _schema,
      onIssue: (path, reason) => issues.add('$path:$reason'),
    ) as Map<String, dynamic>;
    final sensors = sanitized['climate_sensors'] as List<dynamic>;

    expect(sensors, hasLength(2));
    expect(sensors.first, <String, dynamic>{'id': 'air'});
    expect(sensors.last, <String, dynamic>{'id': 'floor', 'temp': 27.5});
    expect(
      issues,
      contains('climate_sensors[0].temp:expected_number'),
    );
    expect(issues, contains('climate_sensors[1]:expected_object'));
  });
}

const _schema = <String, dynamic>{
  'type': 'object',
  'properties': <String, dynamic>{
    'heater_enabled': <String, dynamic>{'type': 'boolean'},
    'target_temp': <String, dynamic>{'type': 'number'},
    'power_meter': <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'voltage_v': <String, dynamic>{'type': 'number'},
        'current_a': <String, dynamic>{'type': 'number'},
      },
    },
    'climate_sensors': <String, dynamic>{
      'type': 'array',
      'items': <String, dynamic>{
        'type': 'object',
        'properties': <String, dynamic>{
          'id': <String, dynamic>{'type': 'string'},
          'temp': <String, dynamic>{'type': 'number'},
        },
      },
    },
  },
};
