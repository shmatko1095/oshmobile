import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/contracts/json_rpc_contract_descriptor.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_jsonrpc_codec.dart';

void main() {
  final codec = TelemetryJsonRpcCodec.fromRuntimeContract(_contract);

  test('decodes current payload without deprecated load_factor', () {
    final result = codec.decodeState(_validPayload());

    expect(result.state.heaterEnabled, isTrue);
    expect(result.state.climateSensors.single.temp, 22.5);
    expect(result.state.toJson(), isNot(contains('load_factor')));
    expect(result.issues, isEmpty);
  });

  test('accepts but does not expose deprecated load_factor', () {
    final result = codec.decodeState(
      _validPayload()..['load_factor'] = 35,
    );

    expect(result.state.heaterEnabled, isTrue);
    expect(result.state.toJson(), isNot(contains('load_factor')));
  });

  test('isolates malformed sensor and power fields', () {
    final payload = _validPayload();
    final sensors = payload['climate_sensors'] as List<Map<String, dynamic>>;
    sensors
      ..first['temp'] = 'bad'
      ..add(<String, dynamic>{
        'id': 'floor',
        'temp_valid': true,
        'humidity_valid': false,
        'temp': 27.5,
      });
    final powerMeter = payload['power_meter'] as Map<String, dynamic>;
    powerMeter['voltage_v'] = 'bad';

    final result = codec.decodeState(payload);
    final stateJson = result.state.toJson();
    final sanitizedPower = stateJson['power_meter'] as Map<String, dynamic>;

    expect(result.state.heaterEnabled, isTrue);
    expect(result.state.climateSensors, hasLength(2));
    expect(result.state.climateSensors.first.temp, isNull);
    expect(result.state.climateSensors.last.temp, 27.5);
    expect(sanitizedPower, isNot(contains('voltage_v')));
    expect(sanitizedPower['current_a'], 1.25);
    expect(stateJson['future_top_level_field'], 'kept');
    expect(
      result.issues.map((issue) => issue.signature),
      contains('climate_sensors[0].temp:expected_number'),
    );
    expect(
      result.issues.map((issue) => issue.signature),
      contains('power_meter.voltage_v:expected_number'),
    );
  });

  test('missing heater state does not hide temperature or power', () {
    final result = codec.decodeState(
      _validPayload()..remove('heater_enabled'),
    );
    final stateJson = result.state.toJson();

    expect(result.state.heaterEnabled, isNull);
    expect(result.state.climateSensors.single.temp, 22.5);
    expect(
      (stateJson['power_meter'] as Map<String, dynamic>)['current_a'],
      1.25,
    );
    expect(stateJson, isNot(contains('heater_enabled')));
    expect(
      result.issues.map((issue) => issue.signature),
      contains('heater_enabled:missing_required_field'),
    );
  });
}

Map<String, dynamic> _validPayload() => <String, dynamic>{
      'climate_sensors': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'air',
          'temp_valid': true,
          'humidity_valid': false,
          'temp': 22.5,
        },
      ],
      'heater_enabled': true,
      'power_meter': <String, dynamic>{
        'online': true,
        'voltage_valid': true,
        'voltage_v': 230.0,
        'current_valid': true,
        'current_a': 1.25,
      },
      'future_top_level_field': 'kept',
    };

const _descriptor = JsonRpcContractDescriptor(
  methodDomain: 'telemetry',
  schemaDomain: 'telemetry',
  major: 1,
);

const _contract = RuntimeDomainContract(
  read: _descriptor,
  patch: _descriptor,
  set: _descriptor,
  stateSchema: _schema,
  patchSchema: null,
  setSchema: null,
);

const _schema = <String, dynamic>{
  'type': 'object',
  'additionalProperties': false,
  'required': <String>['climate_sensors', 'heater_enabled'],
  'properties': <String, dynamic>{
    'climate_sensors': <String, dynamic>{
      'type': 'array',
      'items': <String, dynamic>{
        'type': 'object',
        'additionalProperties': false,
        'required': <String>['id', 'temp_valid', 'humidity_valid'],
        'properties': <String, dynamic>{
          'id': <String, dynamic>{'type': 'string', 'minLength': 1},
          'temp_valid': <String, dynamic>{'type': 'boolean'},
          'humidity_valid': <String, dynamic>{'type': 'boolean'},
          'temp': <String, dynamic>{'type': 'number'},
          'humidity': <String, dynamic>{'type': 'number'},
        },
      },
    },
    'heater_enabled': <String, dynamic>{'type': 'boolean'},
    'load_factor': <String, dynamic>{
      'type': 'integer',
      'minimum': 0,
      'maximum': 100,
      'deprecated': true,
    },
    'power_meter': <String, dynamic>{
      'type': 'object',
      'additionalProperties': false,
      'properties': <String, dynamic>{
        'online': <String, dynamic>{'type': 'boolean'},
        'voltage_valid': <String, dynamic>{'type': 'boolean'},
        'voltage_v': <String, dynamic>{'type': 'number'},
        'current_valid': <String, dynamic>{'type': 'boolean'},
        'current_a': <String, dynamic>{'type': 'number'},
      },
    },
  },
};
