import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'device_mqtt_repo.dart';

/// MQTT repository implementation based on mqtt_client ^10.11.1
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
    // _client.updates!.listen(_onUpdates);
  }

  final String tenantId;
  final String clientIdPrefix;
  final bool useWebSocket;
  final bool secure;
  final int keepAliveSeconds;
  final bool logging;

  // final bool resubscribeOnReconnect;

  final MqttServerClient _client;

  // Credentials (for reconnect)
  String? _userId;
  String? _token;

  // Track per-device controllers and ref-counts
  final Map<String, StreamController<Map<String, dynamic>>> _deviceCtrls = {};
  final Map<String, int> _deviceRefCount = {}; // deviceId -> count

  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _updatesSub;
  StreamSubscription<MqttPublishMessage>? _publishedSub;

  // Track active topic subscriptions (to re-subscribe if needed)
  final Set<String> _activeTopics = {};
  final Set<String> _subscribedTopics = {};

  static String _mkClientId(String prefix) =>
      '$prefix${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecond % 9000))}';

  @override
  bool get isConnected => _client.connectionStatus?.state == MqttConnectionState.connected;

  @override
  Future<void> connect({required String userId, required String token}) async {
    _userId = userId;
    _token = token;

    if (isConnected) return;

    final connMsg =
        MqttConnectMessage().withClientIdentifier(_mkClientId(userId)).startClean().authenticateAs("oshmobile", token);
    _client.connectionMessage = connMsg;

    try {
      await _client.connect();
      _attachStreams();
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
      _client.disconnect();
    } finally {
      // keep controllers open (so UI can remain attached), but you can close if desired
    }
  }

  @override
  Future<void> subscribeDevice(String deviceId) async {
    if (!isConnected) {
      // Attempt auto-connect with saved creds
      if (_userId != null && _token != null) {
        await connect(userId: _userId!, token: _token!);
      } else {
        throw StateError('MQTT not connected and no credentials stored.');
      }
    }

    // Per-device controllers are broadcast streams
    _deviceCtrls.putIfAbsent(
      deviceId,
      () => StreamController<Map<String, dynamic>>.broadcast(),
    );

    // Ref-count to avoid duplicate subs
    _deviceRefCount[deviceId] = (_deviceRefCount[deviceId] ?? 0) + 1;
    if (_deviceRefCount[deviceId]! > 1) return;

    final topics = _topicsForDevice(deviceId);
    for (final t in topics) {
      if (_activeTopics.contains(t)) continue;
      _client.subscribe(t, MqttQos.atLeastOnce);
      _activeTopics.add(t);
    }
  }

  @override
  Future<void> unsubscribeDevice(String deviceId) async {
    final current = _deviceRefCount[deviceId] ?? 0;
    if (current <= 1) {
      _deviceRefCount.remove(deviceId);

      // Physically unsubscribe topics
      for (final t in _topicsForDevice(deviceId)) {
        _client.unsubscribe(t);
        _activeTopics.remove(t);
        _subscribedTopics.remove(t);
      }
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
    if (!isConnected) {
      if (_userId != null && _token != null) {
        await connect(userId: _userId!, token: _token!);
      } else {
        throw StateError('MQTT not connected and no credentials stored.');
      }
    }

    final topic = 'v1/tenants/$tenantId/devices/$deviceId/cmd/inbox';
    final payload = jsonEncode({'action': action, 'args': args ?? {}});
    final builder = MqttClientPayloadBuilder()..addString(payload);
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!, retain: false);
  }

  List<String> _topicsForDevice(String deviceId) => <String>[
        'v1/tenants/$tenantId/devices/$deviceId/state',
        'v1/tenants/$tenantId/devices/$deviceId/telemetry/#',
        '/service/device/telemetry/$deviceId/#'
      ];

  void _onConnected() {
    _attachStreams();
    for (final t in _activeTopics) {
      _client.subscribe(t, MqttQos.atLeastOnce);
    }
  }

  void _attachStreams() {
    // Перенавешиваем на актуальные стримы
    _updatesSub?.cancel();
    _publishedSub?.cancel();

    _updatesSub = _client.updates?.listen(
      _onUpdates,
      onError: (e, st) => print('MQTT updates error: $e'),
    );
  }

  void _onDisconnected() {
    // nothing special; streams stay alive. Reconnect handled by mqtt_client.
  }

  void _onUpdates(List<MqttReceivedMessage<MqttMessage?>> events) {
    for (final evt in events) {
      final topic = evt.topic;
      final msg = evt.payload as MqttPublishMessage;
      final raw = MqttPublishPayload.bytesToStringAsString(msg.payload.message);

      final deviceId = _extractDeviceId(topic);
      if (deviceId == null) continue;

      final ctrl = _deviceCtrls[deviceId];
      if (ctrl == null || ctrl.isClosed) continue;

      final data = _decodePayload(raw);
      ctrl.add(data);
    }
  }

  /// Extracts deviceId from topic:
  /// v1/tenants/{tenantId}/devices/{deviceId}/...
  String? _extractDeviceId(String topic) {
    // v1/tenants/{tenantId}/devices/{deviceId}/...
    final parts = topic.split('/');
    final i = parts.indexOf('devices');
    if (i >= 0 && i + 1 < parts.length) {
      return parts[i + 1];
    }

    // /service/device/telemetry/{deviceId}[/...]
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
      if (d is List) return {'data': d};
      return {'value': d};
    } catch (_) {
      return {'raw': raw};
    }
  }
}
