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
  }) : _client = MqttServerClient(brokerHost, _mkClientId(clientIdPrefix)) {
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

  // ---- Device-level streams (legacy/compat) ----
  final Map<String, StreamController<Map<String, dynamic>>> _deviceCtrls = {};
  final Map<String, int> _deviceRefCount = {}; // deviceId -> count
  final Map<String, List<String>> _deviceActiveTopics = {}; // deviceId -> topics

  // ---- Arbitrary topic JSON subscriptions ----
  final Map<String, StreamController<MqttJson>> _jsonCtrls = {}; // filter -> ctrl
  final Set<String> _jsonActiveFilters = {}; // re-subscribe on reconnect

  // ---- Client-level streams ----
  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _updatesSub;

  // Track active topic strings (union of device topics + json filters)
  final Set<String> _subscribedTopics = {};

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

    // IMPORTANT: left as you designed it. Do not change.
    final connMsg = MqttConnectMessage()
        .withClientIdentifier(_mkClientId(userId))
        .startClean()
        .authenticateAs("oshmobile", token); // <— keep as-is

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

  // --------------- Device-scoped helpers (legacy/compat) ---------------

  @override
  Future<void> subscribeDevice(String deviceId) async {
    await _ensureConnected();

    // Per-device broadcast controller
    _deviceCtrls.putIfAbsent(
      deviceId,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );

    // Ref-count prevents duplicate subscriptions
    _deviceRefCount[deviceId] = (_deviceRefCount[deviceId] ?? 0) + 1;
    if (_deviceRefCount[deviceId]! > 1) return;

    final topics = _topicsForDevice(deviceId);
    _deviceActiveTopics[deviceId] = topics;

    for (final t in topics) {
      if (_subscribedTopics.contains(t)) continue;
      _client.subscribe(t, MqttQos.atLeastOnce);
      _subscribedTopics.add(t);
    }
  }

  @override
  Future<void> unsubscribeDevice(String deviceId) async {
    final current = _deviceRefCount[deviceId] ?? 0;
    if (current <= 1) {
      _deviceRefCount.remove(deviceId);

      // Unsubscribe all topics for that device
      for (final t in _deviceActiveTopics.remove(deviceId) ?? const <String>[]) {
        _client.unsubscribe(t);
        _subscribedTopics.remove(t);
      }

      // Close and remove controller to avoid leaks
      final ctrl = _deviceCtrls.remove(deviceId);
      await ctrl?.close();
    } else {
      _deviceRefCount[deviceId] = current - 1;
    }
  }

  @override
  Stream<Map<String, dynamic>> deviceStream(String deviceId) {
    return _deviceCtrls.putIfAbsent(deviceId, () => StreamController<Map<String, dynamic>>.broadcast()).stream;
  }

  @override
  Future<void> publishCommand(
    String deviceId,
    String action, {
    Map<String, dynamic>? args,
  }) async {
    await _ensureConnected();
    final topic = 'v1/tenants/$tenantId/devices/$deviceId/cmd/inbox';
    final payload = jsonEncode({'action': action, 'args': args ?? {}});
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!, retain: false);
  }

  // --------------- Generic JSON topics (unified repos use these) ---------------

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
    // Re-subscribe device topics
    for (final topics in _deviceActiveTopics.values) {
      for (final t in topics) {
        _client.subscribe(t, MqttQos.atLeastOnce);
        _subscribedTopics.add(t);
      }
    }
    // Re-subscribe JSON filters
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

      // 1) Route to device-level streams
      final deviceId = _extractDeviceId(topic);
      if (deviceId != null) {
        final ctrl = _deviceCtrls[deviceId];
        if (ctrl != null && !ctrl.isClosed) {
          final data = _decodePayload(raw);
          ctrl.add(data);
        }
      }

      // 2) Route to arbitrary JSON subscriptions by matching filters
      if (_jsonCtrls.isNotEmpty) {
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
