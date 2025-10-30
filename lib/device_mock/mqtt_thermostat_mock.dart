import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart';

import 'device_state.dart';
import 'topics.dart';

/// Mock thermostat that behaves like a real device over MQTT.
/// Use only in DEV builds.
class MqttThermostatMock {
  final String brokerHost;
  final int brokerPort;
  final bool useWss;
  final String tenantId;
  final String deviceId;
  final String? username; // JWT or plain user/pass
  final String? password;

  late final MqttServerClient _client;
  final _rand = Random();
  late DeviceState _state;

  Timer? _baseTeleTimer;
  Timer? _rtTickTimer;
  final Map<String, DateTime> _rtLeases = {}; // sessionId -> expiresAt
  double _rtHz = 1.0;
  Set<String>? _rtFields;

  MqttThermostatMock({
    required this.brokerHost,
    required this.brokerPort,
    required this.useWss,
    required this.tenantId,
    required this.deviceId,
    this.username,
    this.password,
  }) {
    _state = DeviceState(tcur: 22.6, ttarget: 23.0, mode: 'heat', output: 'on');
    _client = MqttServerClient(brokerHost, 'dev:$deviceId')
      ..port = brokerPort
      ..logging(on: false)
      ..keepAlivePeriod = 30
      ..secure = false
      ..useWebSocket = useWss
      ..onDisconnected = _onDisconnected;

    // Configure LWT (retained offline)
    final lwtPayload = jsonEncode(
        {'ver': '1', 'device_id': deviceId, 'online': false, 'ts': DateTime.now().toUtc().toIso8601String()});
    _client.connectionMessage = mqtt.MqttConnectMessage()
        .withClientIdentifier('dev:$deviceId')
        .keepAliveFor(30)
        .startClean()
        .withWillTopic(Topics.status(tenantId, deviceId))
        .withWillQos(mqtt.MqttQos.atLeastOnce)
        .withWillRetain()
        .withWillMessage(lwtPayload);

    if (username != null) {
      _client.setProtocolV311();
      _client.connectionMessage = _client.connectionMessage!.authenticateAs(username!, password ?? '');
    }
  }

  Future<void> start() async {
    final conn = await _client.connect();
    if (_client.connectionStatus?.state != mqtt.MqttConnectionState.connected) {
      throw Exception('MQTT connect failed: $conn');
    }
    _state.online = true;

    // Online status (retained)
    _publishJson(
      Topics.status(tenantId, deviceId),
      _state.status(deviceId),
      retained: true,
      qos: mqtt.MqttQos.atLeastOnce,
    );

    // Initial reported (retained)
    _publishJson(
      Topics.reported(tenantId, deviceId),
      _state.toReported(deviceId),
      retained: true,
      qos: mqtt.MqttQos.atLeastOnce,
    );

    // Subscriptions
    _client.subscribe(Topics.desired(tenantId, deviceId), mqtt.MqttQos.atLeastOnce);
    _client.subscribe(Topics.cmdInbox(tenantId, deviceId), mqtt.MqttQos.atLeastOnce);

    _client.updates!.listen(_onMessage);

    // Base telemetry every 30s
    _baseTeleTimer?.cancel();
    _baseTeleTimer = Timer.periodic(const Duration(seconds: 30), (_) => _tickBaseTelemetry());
  }

  void dispose() {
    _baseTeleTimer?.cancel();
    _rtTickTimer?.cancel();
    _client.disconnect();
  }

  // ---- Internals ----

  void _onDisconnected() {
    _state.online = false;
  }

  void _onMessage(List<mqtt.MqttReceivedMessage<mqtt.MqttMessage?>> events) {
    for (final m in events) {
      final payload = (m.payload as mqtt.MqttPublishMessage).payload.message;
      final str = utf8.decode(payload);
      final topic = m.topic;
      try {
        final data = jsonDecode(str) as Map<String, dynamic>;
        if (topic == Topics.desired(tenantId, deviceId)) {
          _handleDesired(data);
        } else if (topic == Topics.cmdInbox(tenantId, deviceId)) {
          _handleCmd(data);
        }
      } catch (_) {
        // ignore parse errors in mock
      }
    }
  }

  void _handleDesired(Map<String, dynamic> msg) {
    final desired = (msg['desired'] ?? {}) as Map<String, dynamic>;
    bool changed = false;

    if (desired.containsKey('ttarget')) {
      _state.ttarget = (desired['ttarget'] as num).toDouble();
      changed = true;
    }
    if (desired.containsKey('mode')) {
      _state.mode = desired['mode'] as String;
      changed = true;
    }
    if (desired.containsKey('schedule_revision')) {
      _state.scheduleRevision = (desired['schedule_revision'] as num).toInt();
      changed = true;
    }

    if (changed) {
      // Simple control law: follow setpoint
      if (_state.ttarget > _state.tcur) {
        _state.output = 'on';
      } else {
        _state.output = 'off';
      }
      _publishJson(Topics.reported(tenantId, deviceId), _state.toReported(deviceId),
          retained: true, qos: mqtt.MqttQos.atLeastOnce);
    }
  }

  void _handleCmd(Map<String, dynamic> msg) {
    final cmd = msg['cmd'] as String? ?? '';
    final corrId = msg['msg_id'] as String? ?? '';
    final replyTo = msg['reply_to'] as String?;
    Map<String, dynamic> ok([Map<String, dynamic>? result]) => {
          'ver': '1',
          'origin': 'device',
          'corr_id': corrId,
          'ok': true,
          'result': result ?? {},
          'ts': DateTime.now().toUtc().toIso8601String()
        };
    Map<String, dynamic> err(String code, String reason) => {
          'ver': '1',
          'origin': 'device',
          'corr_id': corrId,
          'ok': false,
          'code': code,
          'reason': reason,
          'ts': DateTime.now().toUtc().toIso8601String()
        };

    if (replyTo == null) return;

    switch (cmd) {
      case 'stream':
        final args = (msg['args'] ?? {}) as Map<String, dynamic>;
        final enable = args['enable'] == true;
        final hz = (args['hz'] as num?)?.toDouble() ?? 1.0;
        final duration = (args['duration_s'] as num?)?.toInt() ?? 90;
        final sessionId = (args['session_id'] as String?) ?? 'default';
        final fields = (args['fields'] as List?)?.cast<String>();

        if (enable) {
          _rtLeases[sessionId] = DateTime.now().toUtc().add(Duration(seconds: duration));
          _rtHz = hz.clamp(0.1, 2.0);
          _rtFields = fields?.toSet();
          _ensureRtTick();
          _publishJson(replyTo, ok({'hz': _rtHz, 'expires_at': _rtLeases[sessionId]!.toIso8601String()}));
        } else {
          _rtLeases.remove(sessionId);
          _publishJson(replyTo, ok({'stopped': true}));
        }
        break;

      case 'reboot':
        _publishJson(replyTo, ok({'accepted': true, 'eta_s': 2}));
        Future.delayed(const Duration(seconds: 1), () {
          _state.online = false;
          _publishJson(Topics.status(tenantId, deviceId), _state.status(deviceId),
              retained: true, qos: mqtt.MqttQos.atLeastOnce);
        });
        Future.delayed(const Duration(seconds: 3), () {
          _state.online = true;
          _publishJson(Topics.status(tenantId, deviceId), _state.status(deviceId),
              retained: true, qos: mqtt.MqttQos.atLeastOnce);
          _publishJson(Topics.events(tenantId, deviceId),
              {'ver': '1', 'ts': DateTime.now().toUtc().toIso8601String(), 'type': 'rebooted', 'cause': 'user_cmd'});
        });
        break;

      case 'set_output':
        final args = (msg['args'] ?? {}) as Map<String, dynamic>;
        final out = args['output'] as String?;
        if (out == null || (out != 'on' && out != 'off')) {
          _publishJson(replyTo, err('bad_args', 'output must be "on" or "off"'));
          return;
        }
        _state.output = out;
        _publishJson(replyTo, ok({'accepted': true}));
        _publishJson(Topics.reported(tenantId, deviceId), _state.toReported(deviceId),
            retained: true, qos: mqtt.MqttQos.atLeastOnce);
        break;

      case 'start_ota':
        final args = (msg['args'] ?? {}) as Map<String, dynamic>;
        final ver = args['version'] as String? ?? 'X';
        _publishJson(replyTo, ok({'started': true}));
        int pct = 0;
        Timer.periodic(const Duration(milliseconds: 300), (t) {
          pct += 10;
          if (pct >= 100) {
            t.cancel();
            _state.fwVersion = ver;
            _publishJson(Topics.events(tenantId, deviceId),
                {'ver': '1', 'ts': DateTime.now().toUtc().toIso8601String(), 'type': 'ota_done', 'version': ver});
            _publishJson(Topics.status(tenantId, deviceId), _state.status(deviceId),
                retained: true, qos: mqtt.MqttQos.atLeastOnce);
          } else {
            _publishJson(Topics.otaProgress(tenantId, deviceId),
                {'ver': '1', 'ts': DateTime.now().toUtc().toIso8601String(), 'phase': 'download', 'percent': pct});
          }
        });
        break;

      default:
        _publishJson(replyTo, err('unknown_cmd', 'Command not supported'));
    }
  }

  void _tickBaseTelemetry() {
    // Random walk to mimic temperature
    _state.tcur += (_rand.nextDouble() - 0.5) * 0.2;
    if (_state.tcur < _state.ttarget - 0.2) _state.output = 'on';
    if (_state.tcur > _state.ttarget + 0.2) _state.output = 'off';

    _publishJson(
        Topics.telemetry(tenantId, deviceId),
        {
          'ver': '1',
          'device_id': deviceId,
          'ts': DateTime.now().toUtc().toIso8601String(),
          'tcur': double.parse(_state.tcur.toStringAsFixed(1)),
          'output': _state.output
        },
        retained: false,
        qos: mqtt.MqttQos.atMostOnce);
  }

  void _ensureRtTick() {
    _rtTickTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now().toUtc();
      _rtLeases.removeWhere((_, exp) => exp.isBefore(now));
      if (_rtLeases.isEmpty) {
        _rtTickTimer?.cancel();
        _rtTickTimer = null;
        return;
      }
      final Map<String, dynamic> rt = {
        'ver': '1',
        'device_id': deviceId,
        'ts': DateTime.now().toUtc().toIso8601String(),
      };
      final setFields = _rtFields;
      if (setFields == null || setFields.contains('tcur')) {
        _state.tcur += (_rand.nextDouble() - 0.5) * 0.1;
        rt['tcur'] = double.parse(_state.tcur.toStringAsFixed(1));
      }
      if (setFields == null || setFields.contains('p')) {
        rt['p'] = _state.output == 'on' ? 65 + _rand.nextDouble() * 5 : 0.0;
      }
      if (setFields == null || setFields.contains('output')) {
        rt['output'] = _state.output;
      }
      _publishJson(Topics.telemetryRt(tenantId, deviceId), rt, retained: false, qos: mqtt.MqttQos.atMostOnce);
    });
  }

  void _publishJson(String topic, Map<String, dynamic> json,
      {bool retained = false, mqtt.MqttQos qos = mqtt.MqttQos.atLeastOnce}) {
    final b = mqtt.MqttClientPayloadBuilder()..addString(jsonEncode(json));
    _client.publishMessage(topic, qos, b.payload!, retain: retained);
  }
}
