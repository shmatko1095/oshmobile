import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_errors.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/device_state_models.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/devices/details/data/mqtt_telemetry_repository.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_topics.dart';
import 'package:oshmobile/features/settings/data/settings_jsonrpc_codec.dart';
import 'package:oshmobile/features/settings/data/settings_repository_mqtt.dart';
import 'package:oshmobile/features/settings/data/settings_topics.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/sensors/data/sensors_jsonrpc_codec.dart';
import 'package:oshmobile/features/sensors/data/sensors_repository_mqtt.dart';
import 'package:oshmobile/features/sensors/data/sensors_topics.dart';
import 'package:oshmobile/features/device_state/data/device_state_jsonrpc_codec.dart';
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

class FakeDeviceMqttRepo implements DeviceMqttRepo {
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
  Future<void> publishJson(String topic, Map<String, dynamic> payload,
      {int qos = 1, bool retain = false}) async {
    published.add(
        _Published(topic: topic, payload: payload, qos: qos, retain: retain));
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

void main() {
  test('SettingsRepositoryMqtt builds JSON-RPC set request', () async {
    final mqtt = FakeDeviceMqttRepo();
    final topics = SettingsTopics(DeviceMqttTopicsV1('tenant-x'));
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = SettingsRepositoryMqtt(jrpc, topics, 'device-1',
        timeout: const Duration(milliseconds: 200));

    final snap = SettingsSnapshot.fromJson(_settingsPayload());
    final op = repo.saveAll(snap, reqId: 'req-1');

    await Future<void>.delayed(Duration.zero);
    expect(mqtt.published, hasLength(1));
    final pub = mqtt.published.single;
    expect(pub.topic, topics.cmd('device-1'));
    expect(pub.payload['jsonrpc'], '2.0');
    expect(pub.payload['id'], 'req-1');
    expect(pub.payload['method'], SettingsJsonRpcCodec.methodSet);

    final params = pub.payload['params'] as Map<String, dynamic>;
    expect((params['meta'] as Map)['schema'], SettingsJsonRpcCodec.schema);
    expect(params['data'], snap.toJson());

    mqtt.emit(
      topics.rsp('device-1'),
      {
        'jsonrpc': '2.0',
        'id': 'req-1',
        'result': {
          'meta': {'schema': SettingsJsonRpcCodec.schema},
          'data': snap.toJson(),
        }
      },
    );

    await op;
  });

  test('SettingsRepositoryMqtt rejects unknown patch fields', () async {
    final mqtt = FakeDeviceMqttRepo();
    final topics = SettingsTopics(DeviceMqttTopicsV1('tenant-x'));
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = SettingsRepositoryMqtt(jrpc, topics, 'device-1');

    await expectLater(repo.patch({'unknown': 1}), throwsFormatException);
    expect(mqtt.published, isEmpty);
  });

  test('SensorsRepositoryMqtt builds set_temp_calibration patch request',
      () async {
    final mqtt = FakeDeviceMqttRepo();
    final topics = SensorsTopics(DeviceMqttTopicsV1('tenant-x'));
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = SensorsRepositoryMqtt(jrpc, topics, 'device-1',
        timeout: const Duration(milliseconds: 200));

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
    expect(pub.payload['method'], SensorsJsonRpcCodec.methodPatch);

    final params = pub.payload['params'] as Map<String, dynamic>;
    expect((params['meta'] as Map)['schema'], SensorsJsonRpcCodec.schema);
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
          'meta': {'schema': SensorsJsonRpcCodec.schema},
        },
      },
    );

    await op;
  });

  test('SensorsRepositoryMqtt parses sensors.state notification', () async {
    final mqtt = FakeDeviceMqttRepo();
    final topics = SensorsTopics(DeviceMqttTopicsV1('tenant-x'));
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = SensorsRepositoryMqtt(jrpc, topics, 'device-1',
        timeout: const Duration(milliseconds: 200));

    final future = repo.watchState().first;

    mqtt.emit(
      topics.state('device-1'),
      {
        'jsonrpc': '2.0',
        'method': SensorsJsonRpcCodec.methodState,
        'params': {
          'meta': {
            'schema': SensorsJsonRpcCodec.schema,
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

  test('TelemetryRepository joins sensors + telemetry by id', () async {
    final mqtt = FakeDeviceMqttRepo();
    final topics = TelemetryTopics(DeviceMqttTopicsV1('tenant-x'));
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = MqttTelemetryRepositoryImpl(
        jrpc: jrpc, topics: topics, deviceSn: 'device-1');

    await repo.subscribe();

    final future = repo.watchAliases().firstWhere(
          (diff) =>
              diff['sensor.temperature'] != null &&
              diff['sensor.humidity'] != null,
        );

    mqtt.emit(
      topics.stateSensors('device-1'),
      {
        'jsonrpc': '2.0',
        'method': SensorsJsonRpcCodec.methodState,
        'params': {
          'meta': {
            'schema': SensorsJsonRpcCodec.schema,
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

    mqtt.emit(
      topics.stateTelemetry('device-1'),
      {
        'jsonrpc': '2.0',
        'method': TelemetryJsonRpcCodec.methodState,
        'params': {
          'meta': {
            'schema': TelemetryJsonRpcCodec.schema,
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

    final diff = await future;
    expect(diff['sensor.temperature'], 22.6);
    expect(diff['sensor.humidity'], 44.2);
  });

  test('TelemetryRepository maps NotAllowed error', () async {
    final mqtt = FakeDeviceMqttRepo();
    final topics = TelemetryTopics(DeviceMqttTopicsV1('tenant-x'));
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = MqttTelemetryRepositoryImpl(
      jrpc: jrpc,
      topics: topics,
      deviceSn: 'device-1',
      timeout: const Duration(milliseconds: 200),
    );

    final op = repo.set(reqId: 'req-telemetry-set');

    await Future<void>.delayed(Duration.zero);
    mqtt.emit(
      topics.rsp('device-1'),
      {
        'jsonrpc': '2.0',
        'id': 'req-telemetry-set',
        'error': {
          'code': JsonRpcErrorCodes.notAllowed,
          'message': 'Method not allowed'
        }
      },
    );

    await expectLater(op, throwsA(isA<JsonRpcNotAllowed>()));
  });

  test('TelemetryRepository polls telemetry.get periodically', () async {
    final mqtt = FakeDeviceMqttRepo();
    final topics = TelemetryTopics(DeviceMqttTopicsV1('tenant-x'));
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = MqttTelemetryRepositoryImpl(
      jrpc: jrpc,
      topics: topics,
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
    expect(req.payload['method'], TelemetryJsonRpcCodec.methodGet);

    // Respond to the first request to avoid repeated timeouts.
    final reqId = req.payload['id']?.toString();
    mqtt.emit(
      topics.rsp('device-1'),
      {
        'jsonrpc': '2.0',
        'id': reqId,
        'result': {
          'meta': {'schema': TelemetryJsonRpcCodec.schema},
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
    final mqtt = FakeDeviceMqttRepo();
    final topics = DeviceStateTopics(DeviceMqttTopicsV1('tenant-x'));
    final jrpc = JsonRpcClient(mqtt: mqtt, rspTopic: topics.rsp('device-1'));
    final repo = DeviceStateRepositoryMqtt(jrpc, topics, 'device-1',
        timeout: const Duration(milliseconds: 200));

    final future = repo.watchState().first;

    mqtt.emit(
      topics.state('device-1'),
      {
        'jsonrpc': '2.0',
        'method': DeviceStateJsonRpcCodec.methodState,
        'params': {
          'meta': {
            'schema': DeviceStateJsonRpcCodec.schema,
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
}
