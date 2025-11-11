import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'device_mqtt_repo.dart';

/// MQTT repository implementation based on mqtt_client ^10.11.1.
/// Transport-only: knows nothing about domain semantics.
class DeviceMqttRepoImpl implements DeviceMqttRepo {
  DeviceMqttRepoImpl({
    required String brokerHost, // host only, e.g. "mqtt.example.com"
    required int port, // 8883 for TLS, 8083/8084 for WSS
    required this.tenantId,
    this.clientIdPrefix = 'oshmobile',
    this.useWebSocket = false,
    this.secure = false,
    this.keepAliveSeconds = 30,
    this.logging = true,
  }) : _client = MqttServerClient(brokerHost, "") {
    _client.logging(on: logging);

    _client.port = port;
    _client.secure = secure;
    _client.useWebSocket = useWebSocket;
    _client.keepAlivePeriod = keepAliveSeconds;
    _client.autoReconnect = true;

    // Callbacks
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = (t) => _subscribedTopics.add(t);
  }

  final String tenantId;
  final String clientIdPrefix;
  final bool useWebSocket;
  final bool secure;
  final int keepAliveSeconds;
  final bool logging;

  final MqttServerClient _client;

  // Credentials (persisted to support reconnect-on-demand)
  String? _userId;
  String? _token;

  // ---- Arbitrary topic JSON subscriptions ----
  final Map<String, StreamController<MqttJson>> _jsonCtrls = {}; // filter -> ctrl
  final Set<String> _jsonActiveFilters = {}; // re-subscribe on reconnect
// Track active topic strings (union of device topics + json filters)
  final Set<String> _subscribedTopics = {};

  // ---- Client-level streams ----
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _updatesSub;

  static String _mkClientId(String prefix) =>
      '$prefix${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';

  // ---------------- DeviceMqttRepo (transport) ----------------

  @override
  bool get isConnected => _client.connectionStatus?.state == MqttConnectionState.connected;

  @override
  Future<void> connect({required String userId, required String token}) async {
    _userId = userId;
    _token = token;

    if (isConnected) {
      _attachUpdatesStream();
      return;
    }

    final connMsg =
        MqttConnectMessage().withClientIdentifier(_mkClientId(userId)).startClean().authenticateAs(userId, token);

    _client.connectionMessage = connMsg;

    try {
      await _client.connect();
      _attachUpdatesStream();
      // Re-subscribe active topics/filters after a fresh connect.
      _resubscribeAll();
    } on Exception {
      _client.disconnect();
      rethrow;
    }
  }

  @override
  Future<void> reconnect({required String userId, required String token}) async {
    _userId = userId;
    _token = token;
    try {
      _client.disconnect();
    } catch (_) {}
    await connect(userId: userId, token: token);
  }

  @override
  Future<void> disconnect() async {
    try {
      await _updatesSub?.cancel();
      _updatesSub = null;
    } catch (_) {}
    try {
      _client.disconnect();
    } finally {
      // We intentionally keep controllers open; callers may still listen.
      // If you prefer, you can close device/json controllers here.
    }
  }

  @override
  Stream<MqttJson> subscribeJson(String topicFilter, {int qos = 1}) {
    // Create or return a broadcast controller for this filter
    final ctrl = _jsonCtrls.putIfAbsent(topicFilter, () {
      // Subscribe immediately if connected
      if (isConnected && !_subscribedTopics.contains(topicFilter)) {
        _client.subscribe(topicFilter, _qosFromInt(qos));
        _subscribedTopics.add(topicFilter);
      }
      _jsonActiveFilters.add(topicFilter);
      return StreamController<MqttJson>.broadcast(
        onListen: () async {
          // Ensure subscribed when a listener appears
          if (isConnected && !_subscribedTopics.contains(topicFilter)) {
            _client.subscribe(topicFilter, _qosFromInt(qos));
            _subscribedTopics.add(topicFilter);
          }
        },
        onCancel: () {
          // Keep active to survive reconnects (comment out if you want auto-unsub when no listeners)
        },
      );
    });

    return ctrl.stream;
  }

  @override
  Future<void> publishJson(String topic, Map<String, dynamic> payload, {int qos = 1, bool retain = false}) async {
    await _ensureConnected();
    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(payload));
    _client.publishMessage(topic, _qosFromInt(qos), builder.payload!, retain: retain);
  }

  // ---------------- Internal plumbing ----------------

  Future<void> _ensureConnected() async {
    if (isConnected) return;
    if (_userId != null && _token != null) {
      await connect(userId: _userId!, token: _token!);
    } else {
      throw StateError('MQTT not connected and no stored credentials.');
    }
  }

  void _onConnected() {
    _attachUpdatesStream();
    _resubscribeAll();
  }

  void _onDisconnected() {
    // Keep controllers alive; autoReconnect will reconnect.
  }

  void _attachUpdatesStream() {
    _updatesSub?.cancel();
    _updatesSub = _client.updates?.listen(
      _onUpdates,
      onError: (e, st) {
        if (logging) {
          // ignore: avoid_print
          print('MQTT updates error: $e');
        }
      },
    );
  }

  void _resubscribeAll() {
    for (final f in _jsonActiveFilters) {
      _client.subscribe(f, MqttQos.atLeastOnce);
      _subscribedTopics.add(f);
    }
  }

  void _onUpdates(List<MqttReceivedMessage<MqttMessage?>> events) {
    for (final evt in events) {
      final topic = evt.topic;
      final msg = evt.payload as MqttPublishMessage;
      final raw = MqttPublishPayload.bytesToStringAsString(msg.payload.message);

      if (_jsonCtrls.isEmpty) continue;

      final decoded = _decodePayload(raw);
      final item = MqttJson(topic, decoded);

      for (final entry in _jsonCtrls.entries) {
        final filter = entry.key;
        final ctrl = entry.value;
        if (!ctrl.isClosed && _matchesTopicFilter(filter, topic)) {
          ctrl.add(item);
        }
      }
    }
  }

  // Topics for a device: adjust to your firmware structure
  List<String> _topicsForDevice(String deviceId) => <String>[
        'v1/tenants/$tenantId/devices/$deviceId/state',
        'v1/tenants/$tenantId/devices/$deviceId/telemetry/#',
        '/service/device/telemetry/$deviceId/#',
      ];

  /// Extracts deviceId from topic:
  /// - v1/tenants/{tenantId}/devices/{deviceId}/...
  /// - /service/device/telemetry/{deviceId}[/...]
  String? _extractDeviceId(String topic) {
    final parts = topic.split('/');
    final i = parts.indexOf('devices');
    if (i >= 0 && i + 1 < parts.length) {
      return parts[i + 1];
    }
    const svcPrefix = '/service/device/telemetry/';
    if (topic.startsWith(svcPrefix)) {
      final rest = topic.substring(svcPrefix.length);
      final id = rest.split('/').firstWhere((e) => e.isNotEmpty, orElse: () => '');
      return id.isEmpty ? null : id;
    }
    return null;
  }

  Map<String, dynamic> _decodePayload(String raw) {
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return Map<String, dynamic>.from(d);
      if (d is List) return {'data': d};
      return {'value': d};
    } catch (_) {
      return {'raw': raw};
    }
  }

  // MQTT topic filter matching with + and # wildcards.
  bool _matchesTopicFilter(String filter, String topic) {
    // normalize leading/trailing slashes
    final f = filter.split('/');
    final t = topic.split('/');

    for (int i = 0, j = 0; i < f.length; i++, j++) {
      final ft = f[i];
      if (ft == '#') return true; // multi-level wildcard matches the rest
      if (j >= t.length) return false; // topic shorter than filter
      if (ft == '+') continue; // single-level wildcard
      if (ft != t[j]) return false;
    }
    // If filter ended but topic has remaining levels, filter must have ended with '#'
    return t.length == f.length;
  }

  MqttQos _qosFromInt(int qos) {
    switch (qos) {
      case 2:
        return MqttQos.exactlyOnce;
      case 1:
        return MqttQos.atLeastOnce;
      case 0:
      default:
        return MqttQos.atMostOnce;
    }
  }
}
