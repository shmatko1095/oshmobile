import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/device_state_models.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/devices/details/data/mqtt_telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_topics.dart';
import 'package:oshmobile/features/settings/data/settings_repository_mqtt.dart';
import 'package:oshmobile/features/settings/data/settings_topics.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/sensors/data/sensors_repository_mqtt.dart';
import 'package:oshmobile/features/sensors/data/sensors_topics.dart';
import 'package:oshmobile/features/schedule/data/schedule_repository_mqtt.dart';
import 'package:oshmobile/features/schedule/data/schedule_topics.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/device_state/data/device_state_repository_mqtt.dart';
import 'package:oshmobile/features/device_state/data/device_state_topics.dart';

class _Published {
  final String topic;
  final Map<String, dynamic> payload;
  final int qos;
  final bool retain;

  _Published({
    required this.topic,
    required this.payload,
    required this.qos,
    required this.retain,
  });
}

class _FakeDeviceMqttRepo implements DeviceMqttRepo {
  @override
  bool isConnected = true;

  final StreamController<DeviceMqttConnEvent> _connCtrl =
      StreamController<DeviceMqttConnEvent>.broadcast();
  final List<_Published> published = [];
  final List<_Sub> _subs = [];

  @override
  Stream<DeviceMqttConnEvent> get connEvents => _connCtrl.stream;

  @override
  Future<void> connect({required String userId, required String token}) async {
    isConnected = true;
  }

  @override
  Future<void> reconnect(
      {required String userId, required String token}) async {
    isConnected = true;
  }

  @override
  Future<void> disconnect() async {
    isConnected = false;
  }

  @override
  Future<void> disposeSession() async {
    for (final sub in _subs) {
      await sub.ctrl.close();
    }
    await _connCtrl.close();
  }

  @override
  Stream<MqttJson> subscribeJson(String topicFilter, {int qos = 1}) {
    final ctrl = StreamController<MqttJson>.broadcast();
    _subs.add(_Sub(filter: topicFilter, ctrl: ctrl));
    return ctrl.stream;
  }

  @override
  Future<bool> publishJson(String topic, Map<String, dynamic> payload,
      {int qos = 1, bool retain = false}) async {
    if (!isConnected) return false;
    published.add(
        _Published(topic: topic, payload: payload, qos: qos, retain: retain));
    return true;
  }

  void emit(String topic, Map<String, dynamic> payload) {
    for (final sub in _subs) {
      if (_match(sub.filter, topic)) {
        sub.ctrl.add(MqttJson(topic, payload));
      }
    }
  }

  bool _match(String filter, String topic) {
    final f = filter.split('/');
    final t = topic.split('/');
    var ti = 0;
    for (var fi = 0; fi < f.length; fi++) {
      final part = f[fi];
      if (part == '#') return true;
      if (ti >= t.length) return false;
      if (part == '+') {
        ti += 1;
        continue;
      }
      if (part != t[ti]) return false;
      ti += 1;
    }
    return ti == t.length;
  }
}

class _Sub {
  final String filter;
  final StreamController<MqttJson> ctrl;

  _Sub({required this.filter, required this.ctrl});
}

Map<String, dynamic> _settingsPayload() => {
      'display': {
        'activeBrightness': 100,
        'idleBrightness': 10,
        'idleTime': 30,
        'dimOnIdle': true,
        'language': 'en',
      },
      'update': {
        'autoUpdateEnabled': false,
        'updateAtMidnight': false,
        'checkIntervalMin': 60,
      },
      'time': {
        'auto': true,
        'timeZone': 2,
      },
    };

String _contractIdForDomain(String domain) {
  switch (domain) {
    case 'device':
      return 'device_state@1';
    default:
      return '$domain@1';
  }
}

DeviceRuntimeContracts _runtimeContractsFor(Map<String, Set<String>> domains) {
  Map<String, dynamic> schemaFor(
    String domain,
    String operation,
  ) {
    if (domain == 'settings') {
      if (operation == 'patch') {
        return {
          'type': 'object',
          'additionalProperties': false,
          'properties': {
            'display': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'activeBrightness': {'type': 'integer'},
                'idleBrightness': {'type': 'integer'},
                'idleTime': {'type': 'integer'},
                'dimOnIdle': {'type': 'boolean'},
                'language': {'type': 'string'},
              },
            },
            'update': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'autoUpdateEnabled': {'type': 'boolean'},
                'updateAtMidnight': {'type': 'boolean'},
                'checkIntervalMin': {'type': 'integer'},
              },
            },
            'time': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'auto': {'type': 'boolean'},
                'timeZone': {'type': 'integer'},
              },
            },
            'control': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'model': {'type': 'string'},
                'maxFloorTemp': {'type': 'number'},
                'maxFloorTempLimitEnabled': {'type': 'boolean'},
                'maxFloorTempFailSafe': {'type': 'boolean'},
              },
            },
          },
        };
      }

      if (operation == 'set' || operation == 'state') {
        return {
          'type': 'object',
          'additionalProperties': false,
          'required': ['display', 'update', 'time'],
          'properties': {
            'display': {
              'type': 'object',
              'additionalProperties': false,
              'required': [
                'activeBrightness',
                'idleBrightness',
                'idleTime',
                'dimOnIdle',
                'language',
              ],
              'properties': {
                'activeBrightness': {'type': 'integer'},
                'idleBrightness': {'type': 'integer'},
                'idleTime': {'type': 'integer'},
                'dimOnIdle': {'type': 'boolean'},
                'language': {'type': 'string'},
              },
            },
            'update': {
              'type': 'object',
              'additionalProperties': false,
              'required': [
                'autoUpdateEnabled',
                'updateAtMidnight',
                'checkIntervalMin',
              ],
              'properties': {
                'autoUpdateEnabled': {'type': 'boolean'},
                'updateAtMidnight': {'type': 'boolean'},
                'checkIntervalMin': {'type': 'integer'},
              },
            },
            'time': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['auto', 'timeZone'],
              'properties': {
                'auto': {'type': 'boolean'},
                'timeZone': {'type': 'integer'},
              },
            },
            'control': {
              'type': 'object',
              'additionalProperties': false,
              'properties': {
                'model': {'type': 'string'},
                'maxFloorTemp': {'type': 'number'},
                'maxFloorTempLimitEnabled': {'type': 'boolean'},
                'maxFloorTempFailSafe': {'type': 'boolean'},
              },
            },
          },
        };
      }
    }

    if (domain == 'sensors') {
      if (operation == 'patch') {
        return {
          'type': 'object',
          'additionalProperties': false,
          'properties': {
            'rename': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['id', 'name'],
              'properties': {
                'id': {'type': 'string', 'minLength': 1, 'maxLength': 31},
                'name': {'type': 'string', 'maxLength': 31},
              },
            },
            'set_ref': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['id'],
              'properties': {
                'id': {'type': 'string', 'minLength': 1, 'maxLength': 31},
              },
            },
            'set_temp_calibration': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['id', 'value'],
              'properties': {
                'id': {'type': 'string', 'minLength': 1, 'maxLength': 31},
                'value': {
                  'type': 'number',
                  'minimum': -10,
                  'maximum': 10,
                  'multipleOf': 0.5,
                },
              },
            },
            'remove': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['id'],
              'properties': {
                'id': {'type': 'string', 'minLength': 1, 'maxLength': 31},
                'leave': {'type': 'boolean'},
              },
            },
            'pairing': {'type': 'object'},
          },
          'anyOf': [
            {
              'required': ['rename']
            },
            {
              'required': ['set_ref']
            },
            {
              'required': ['set_temp_calibration']
            },
            {
              'required': ['remove']
            },
            {
              'required': ['pairing']
            },
          ],
        };
      }

      if (operation == 'set') {
        return {
          'type': 'object',
          'additionalProperties': false,
          'required': ['items'],
          'properties': {
            'items': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['id', 'name', 'ref'],
                'properties': {
                  'id': {'type': 'string', 'minLength': 1, 'maxLength': 31},
                  'name': {'type': 'string', 'maxLength': 31},
                  'ref': {'type': 'boolean'},
                },
              },
            },
          },
        };
      }

      if (operation == 'state') {
        return {
          'type': 'object',
          'additionalProperties': false,
          'required': ['pairing', 'items'],
          'properties': {
            'pairing': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['enabled', 'transport', 'timeout_sec', 'started_ts'],
              'properties': {
                'enabled': {'type': 'boolean'},
                'transport': {'type': 'string', 'const': 'zigbee'},
                'timeout_sec': {'type': 'integer', 'minimum': 0},
                'started_ts': {'type': 'integer', 'minimum': 0},
              },
            },
            'items': {
              'type': 'array',
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': [
                  'id',
                  'name',
                  'ref',
                  'transport',
                  'removable',
                  'kind',
                  'temp_calibration',
                ],
                'properties': {
                  'id': {'type': 'string', 'minLength': 1, 'maxLength': 31},
                  'name': {'type': 'string', 'maxLength': 31},
                  'ref': {'type': 'boolean'},
                  'transport': {'type': 'string', 'const': 'wired'},
                  'removable': {'type': 'boolean'},
                  'kind': {
                    'type': 'string',
                    'enum': ['generic', 'air', 'floor'],
                  },
                  'temp_calibration': {
                    'type': 'number',
                    'minimum': -10,
                    'maximum': 10,
                    'multipleOf': 0.5,
                  },
                },
              },
            },
          },
        };
      }
    }

    if (domain == 'schedule') {
      final pointSchema = {
        'type': 'object',
        'additionalProperties': false,
        'required': ['temp', 'hh', 'mm', 'mask'],
        'properties': {
          'temp': {'type': 'number'},
          'hh': {'type': 'integer', 'minimum': 0, 'maximum': 23},
          'mm': {'type': 'integer', 'minimum': 0, 'maximum': 59},
          'mask': {'type': 'integer', 'minimum': 0, 'maximum': 127},
        },
      };
      final listSchema = {
        'type': 'array',
        'items': pointSchema,
      };
      final rangeSchema = {
        'type': 'object',
        'additionalProperties': false,
        'required': ['min', 'max'],
        'properties': {
          'min': {'type': 'number'},
          'max': {'type': 'number'},
        },
      };
      final pointsProps = {
        'off': listSchema,
        'on': listSchema,
        'daily': listSchema,
        'weekly': listSchema,
        'range': rangeSchema,
      };
      if (operation == 'state' || operation == 'set') {
        return {
          'type': 'object',
          'additionalProperties': false,
          'required': ['mode', 'points'],
          'properties': {
            'mode': {
              'type': 'string',
              'enum': ['off', 'on', 'daily', 'weekly', 'range'],
            },
            'points': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['off', 'on', 'daily', 'weekly', 'range'],
              'properties': pointsProps,
            },
          },
        };
      }
      if (operation == 'patch') {
        return {
          'type': 'object',
          'additionalProperties': false,
          'properties': {
            'mode': {
              'type': 'string',
              'enum': ['off', 'on', 'daily', 'weekly', 'range'],
            },
            'points': {
              'type': 'object',
              'additionalProperties': false,
              'properties': pointsProps,
              'anyOf': [
                {
                  'required': ['off']
                },
                {
                  'required': ['on']
                },
                {
                  'required': ['daily']
                },
                {
                  'required': ['weekly']
                },
                {
                  'required': ['range']
                },
              ],
            },
          },
          'anyOf': [
            {
              'required': ['mode']
            },
            {
              'required': ['points']
            },
          ],
        };
      }
    }

    if (domain == 'telemetry' && operation == 'state') {
      return {
        'type': 'object',
        'additionalProperties': false,
        'required': ['climate_sensors', 'heater_enabled', 'load_factor'],
        'properties': {
          'climate_sensors': {
            'type': 'array',
            'items': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['id', 'temp_valid', 'humidity_valid'],
              'properties': {
                'id': {'type': 'string', 'minLength': 1, 'maxLength': 31},
                'temp_valid': {'type': 'boolean'},
                'humidity_valid': {'type': 'boolean'},
                'temp': {'type': 'number'},
                'humidity': {'type': 'number'},
              },
              'allOf': [
                {
                  'if': {
                    'type': 'object',
                    'properties': {
                      'temp_valid': {'const': true},
                    },
                  },
                  'then': {
                    'type': 'object',
                    'required': ['temp'],
                  },
                },
                {
                  'if': {
                    'type': 'object',
                    'properties': {
                      'humidity_valid': {'const': true},
                    },
                  },
                  'then': {
                    'type': 'object',
                    'required': ['humidity'],
                  },
                },
              ],
            },
          },
          'heater_enabled': {'type': 'boolean'},
          'load_factor': {'type': 'integer'},
        },
      };
    }

    if (domain == 'device' && operation == 'state') {
      return {
        'type': 'object',
        'required': ['Uptime', 'Relay cycles', 'Chip temp', 'PCB temp'],
        'properties': {
          'Uptime': {'type': 'string'},
          'Relay cycles': {'type': 'integer'},
          'Chip temp': {'type': 'number'},
          'PCB temp': {'type': 'number'},
        },
      };
    }

    return {'type': 'object'};
  }

  final bundle = DeviceConfigurationBundle.fromJson({
    'configuration_id': 'cfg-1',
    'model_id': 'model-1',
    'revision': 1,
    'status': 'approved',
    'firmware_version': '1.0.0',
    'configuration': {
      'schema_version': 1,
      'integrations': {
        'oshmobile': {
          'layout': 'test',
          'domains': {
            for (final entry in domains.entries)
              entry.key: {
                'contract_id': _contractIdForDomain(entry.key),
              },
          },
          'widgets': const [],
          'settings_groups': const [],
          'collections': const [],
          'controls': const [],
        },
      },
    },
    'runtime_contracts': [
      for (final entry in domains.entries)
        {
          'domain': entry.key,
          'contract_id': _contractIdForDomain(entry.key),
          'definition': {
            'domain': entry.key,
            'schema': _contractIdForDomain(entry.key),
            'wire': {
              if (entry.value.contains('state'))
                'state': schemaFor(entry.key, 'state'),
              if (entry.value.contains('patch'))
                'patch': schemaFor(entry.key, 'patch'),
              if (entry.value.contains('set'))
                'set': schemaFor(entry.key, 'set'),
            },
          },
        },
    ],
  });

  final runtimeContracts = DeviceRuntimeContracts();
  final resolved = runtimeContracts.applyRuntimeBundle(bundle);
  if (resolved.missingContracts.isNotEmpty ||
      resolved.unsupportedContracts.isNotEmpty) {
    throw StateError(
      'Failed to resolve runtime contracts for test bundle: '
      'missing=${resolved.missingContracts}, '
      'unsupported=${resolved.unsupportedContracts}',
    );
  }
  return runtimeContracts;
}

void main() {
  test('SettingsRepositoryMqtt builds JSON-RPC set request', () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'settings': {'state', 'patch', 'set'},
    });
    final topics = SettingsTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = SettingsRepositoryMqtt(jrpc, topics, 'device-1',
        contracts: contracts, timeout: const Duration(milliseconds: 200));

    final snap = SettingsSnapshot.fromJson(_settingsPayload());
    final op = repo.saveAll(snap, reqId: 'req-1');

    await Future<void>.delayed(Duration.zero);
    expect(mqtt.published, hasLength(1));
    final pub = mqtt.published.single;
    expect(pub.topic, topics.cmd('device-1'));
    expect(pub.payload['jsonrpc'], '2.0');
    expect(pub.payload['id'], 'req-1');
    expect(pub.payload['method'], contracts.settings.set.method('set'));

    final params = pub.payload['params'] as Map<String, dynamic>;
    expect((params['meta'] as Map)['schema'], contracts.settings.read.schema);
    expect(params['data'], snap.toJson());

    mqtt.emit(
      topics.rsp('device-1'),
      {
        'jsonrpc': '2.0',
        'id': 'req-1',
        'result': {
          'meta': {'schema': contracts.settings.set.schema},
          'data': snap.toJson(),
        }
      },
    );

    await op;
  });

  test('SettingsRepositoryMqtt rejects unknown patch fields', () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'settings': {'state', 'patch', 'set'},
    });
    final topics = SettingsTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = SettingsRepositoryMqtt(
      jrpc,
      topics,
      'device-1',
      contracts: contracts,
    );

    await expectLater(repo.patch({'unknown': 1}), throwsFormatException);
    expect(mqtt.published, isEmpty);
  });

  test('JsonRpcClient request fails fast when transport is disconnected',
      () async {
    final mqtt = _FakeDeviceMqttRepo()..isConnected = false;
    final contracts = _runtimeContractsFor({
      'settings': {'state', 'patch', 'set'},
    });
    final topics = SettingsTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));

    await expectLater(
      jrpc.request(
        cmdTopic: topics.cmd('device-1'),
        method: contracts.settings.read.method('get'),
        meta: JsonRpcMeta(
          schema: contracts.settings.read.schema,
          src: 'app',
          ts: 1,
        ),
        reqId: 'req-disconnected',
        data: null,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('SensorsRepositoryMqtt builds set_temp_calibration patch request',
      () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'sensors': {'state', 'patch', 'set'},
    });
    final topics = SensorsTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = SensorsRepositoryMqtt(jrpc, topics, 'device-1',
        contracts: contracts, timeout: const Duration(milliseconds: 200));

    final op = repo.patch(
      const SensorsPatchSetTempCalibration(id: 'air', value: 1.5),
      reqId: 'req-sensors-patch',
    );

    await Future<void>.delayed(Duration.zero);
    expect(mqtt.published, hasLength(1));
    final pub = mqtt.published.single;
    expect(pub.topic, topics.cmd('device-1'));
    expect(pub.payload['jsonrpc'], '2.0');
    expect(pub.payload['id'], 'req-sensors-patch');
    expect(pub.payload['method'], contracts.sensors.patch.method('patch'));

    final params = pub.payload['params'] as Map<String, dynamic>;
    expect((params['meta'] as Map)['schema'], contracts.sensors.read.schema);
    expect(
      params['data'],
      {
        'set_temp_calibration': {
          'id': 'air',
          'value': 1.5,
        },
      },
    );

    mqtt.emit(
      topics.rsp('device-1'),
      {
        'jsonrpc': '2.0',
        'id': 'req-sensors-patch',
        'result': {
          'meta': {'schema': contracts.sensors.patch.schema},
        },
      },
    );

    await op;
  });

  test('SensorsRepositoryMqtt rejects patch violating schema constraints',
      () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'sensors': {'state', 'patch', 'set'},
    });
    final topics = SensorsTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = SensorsRepositoryMqtt(
      jrpc,
      topics,
      'device-1',
      contracts: contracts,
    );

    await expectLater(
      repo.patch(
        const SensorsPatchSetTempCalibration(id: 'air', value: 1.3),
      ),
      throwsFormatException,
    );
    expect(mqtt.published, isEmpty);
  });

  test('SensorsRepositoryMqtt parses sensors.state notification', () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'sensors': {'state', 'patch', 'set'},
    });
    final topics = SensorsTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = SensorsRepositoryMqtt(jrpc, topics, 'device-1',
        contracts: contracts, timeout: const Duration(milliseconds: 200));

    final future = repo.watchState().first;

    mqtt.emit(
      topics.state('device-1'),
      {
        'jsonrpc': '2.0',
        'method': contracts.sensors.read.method('state'),
        'params': {
          'meta': {
            'schema': contracts.sensors.read.schema,
            'src': 'device',
            'ts': 1
          },
          'data': {
            'pairing': {
              'enabled': false,
              'transport': 'zigbee',
              'timeout_sec': 0,
              'started_ts': 0,
            },
            'items': [
              {
                'id': 'air',
                'name': 'Air',
                'ref': true,
                'transport': 'wired',
                'removable': false,
                'kind': 'air',
                'temp_calibration': 0.0,
              },
              {
                'id': 'floor',
                'name': 'Floor',
                'ref': false,
                'transport': 'wired',
                'removable': false,
                'kind': 'floor',
                'temp_calibration': -0.5,
              },
            ],
          }
        }
      },
    );

    final snap = await future;
    expect(snap.items.length, 2);
    expect(snap.items.first.ref, true);
    expect(snap.items.first.tempCalibration, 0.0);
  });

  test('ScheduleRepositoryMqtt builds JSON-RPC set request', () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'schedule': {'state', 'patch', 'set'},
    });
    final topics = ScheduleTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = ScheduleRepositoryMqtt(
      jrpc,
      topics,
      'device-1',
      contracts: contracts,
      timeout: const Duration(milliseconds: 200),
    );

    final snap = CalendarSnapshot(
      mode: CalendarMode.on,
      range: const ScheduleRange(min: 15, max: 18.5),
      lists: {
        CalendarMode.off: const [],
        CalendarMode.on: const [
          SchedulePoint(
            time: TimeOfDay(hour: 6, minute: 0),
            daysMask: WeekdayMask.all,
            temp: 21.0,
          ),
        ],
        CalendarMode.daily: const [],
        CalendarMode.weekly: const [],
      },
    );

    final op = repo.saveAll(snap, reqId: 'req-schedule-set');

    await Future<void>.delayed(Duration.zero);
    expect(mqtt.published, hasLength(1));
    final pub = mqtt.published.single;
    expect(pub.topic, topics.cmd('device-1'));
    expect(pub.payload['jsonrpc'], '2.0');
    expect(pub.payload['id'], 'req-schedule-set');
    expect(pub.payload['method'], contracts.schedule.set.method('set'));

    final params = pub.payload['params'] as Map<String, dynamic>;
    expect((params['meta'] as Map)['schema'], contracts.schedule.read.schema);
    final data = params['data'] as Map<String, dynamic>;
    expect(data['mode'], 'on');
    expect((data['points'] as Map<String, dynamic>).containsKey('on'), isTrue);
    expect(
        (data['points'] as Map<String, dynamic>).containsKey('range'), isTrue);

    mqtt.emit(
      topics.rsp('device-1'),
      {
        'jsonrpc': '2.0',
        'id': 'req-schedule-set',
        'result': {
          'meta': {'schema': contracts.schedule.set.schema},
          'data': data,
        },
      },
    );

    await op;
  });

  test('ScheduleRepositoryMqtt rejects mode outside schema enum', () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'schedule': {'state', 'patch', 'set'},
    });
    final topics = ScheduleTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = ScheduleRepositoryMqtt(
      jrpc,
      topics,
      'device-1',
      contracts: contracts,
      timeout: const Duration(milliseconds: 200),
    );

    await expectLater(
      repo.setMode(const CalendarMode('unsupported')),
      throwsFormatException,
    );
    expect(mqtt.published, isEmpty);
  });

  test('TelemetryRepository emits canonical telemetry.state snapshots',
      () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'telemetry': {'state'},
    });
    final topics = TelemetryTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = MqttTelemetryRepositoryImpl(
      jrpc: jrpc,
      topics: topics,
      contracts: contracts,
      deviceSn: 'device-1',
    );

    await repo.subscribe();

    final future = repo.watchState().firstWhere(
          (state) =>
              state.climateSensors.isNotEmpty &&
              state.climateSensors.first.temp == 22.6,
        );

    mqtt.emit(
      topics.stateTelemetry('device-1'),
      {
        'jsonrpc': '2.0',
        'method': contracts.telemetry.read.method('state'),
        'params': {
          'meta': {
            'schema': contracts.telemetry.read.schema,
            'src': 'device',
            'ts': 2
          },
          'data': {
            'climate_sensors': [
              {
                'id': 'air',
                'temp_valid': true,
                'humidity_valid': true,
                'temp': 22.6,
                'humidity': 44.2,
              },
              {
                'id': 'floor',
                'temp_valid': true,
                'humidity_valid': false,
                'temp': 27.1,
              }
            ],
            'heater_enabled': false,
            'load_factor': 18,
          }
        }
      },
    );

    final state = await future;
    expect(state.heaterEnabled, isFalse);
    expect(state.loadFactor, 18);
    expect(state.climateSensors, hasLength(2));
    expect(state.climateSensors.first.id, 'air');
    expect(state.climateSensors.first.temp, 22.6);
    expect(state.climateSensors.first.humidity, 44.2);
  });

  test('TelemetryRepository polls telemetry.get periodically', () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'telemetry': {'state'},
    });
    final topics = TelemetryTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = MqttTelemetryRepositoryImpl(
      jrpc: jrpc,
      topics: topics,
      contracts: contracts,
      deviceSn: 'device-1',
      timeout: const Duration(milliseconds: 200),
      pollInterval: const Duration(milliseconds: 50),
    );

    await repo.subscribe();

    // Allow poll timer to enqueue a request.
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(mqtt.published, isNotEmpty);

    final req = mqtt.published.first;
    expect(req.topic, topics.cmd('device-1'));
    expect(req.payload['jsonrpc'], '2.0');
    expect(req.payload['method'], contracts.telemetry.read.method('get'));

    // Respond to the first request to avoid repeated timeouts.
    final reqId = req.payload['id']?.toString();
    mqtt.emit(
      topics.rsp('device-1'),
      {
        'jsonrpc': '2.0',
        'id': reqId,
        'result': {
          'meta': {'schema': contracts.telemetry.read.schema},
          'data': {
            'climate_sensors': [
              {
                'id': 'air',
                'temp_valid': true,
                'humidity_valid': true,
                'temp': 21.0,
                'humidity': 40.0,
              }
            ],
            'heater_enabled': false,
            'load_factor': 18,
          }
        }
      },
    );

    // Ensure we can stop polling without errors.
    await repo.unsubscribe();
  });

  test('DeviceStateRepository parses state notification', () async {
    final mqtt = _FakeDeviceMqttRepo();
    final contracts = _runtimeContractsFor({
      'device': {'state'},
    });
    final topics = DeviceStateTopics(DeviceMqttTopicsV1('tenant-x'), contracts);
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = DeviceStateRepositoryMqtt(jrpc, topics, 'device-1',
        contracts: contracts, timeout: const Duration(milliseconds: 200));

    final future = repo.watchState().first;

    mqtt.emit(
      topics.state('device-1'),
      {
        'jsonrpc': '2.0',
        'method': contracts.device.read.method('state'),
        'params': {
          'meta': {
            'schema': contracts.device.read.schema,
            'src': 'device',
            'ts': 1
          },
          'data': {
            'Uptime': '0 days 0 hours 1 min 0 sec',
            'Relay cycles': 2,
            'Chip temp': 40.0,
            'PCB temp': 35.0,
          }
        }
      },
    );

    final snap = await future;
    expect(snap, isA<DeviceStatePayload>());
    expect(snap.raw['Chip temp'], 40.0);
  });

  test('DeviceStatePayload tolerates extra fields in payload', () {
    final parsed = DeviceStatePayload.tryParse({
      'Uptime': '1d',
      'Relay cycles': 42,
      'Chip temp': 55.2,
      'PCB temp': 49.8,
      'fw': '1.2.3',
    });

    expect(parsed, isNotNull);
    expect(parsed!.raw['fw'], '1.2.3');
  });
}
