import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/mqtt/app_device_id_provider.dart';

import 'device_mqtt_repo.dart';

/// Transport-only MQTT repo.
/// Notes:
/// - Keep auth style compatible with broker config (username=clientId).
/// - Avoid autoReconnect if you manage session lifecycle manually.
class DeviceMqttRepoImpl implements DeviceMqttRepo {
  DeviceMqttRepoImpl({
    required AppDeviceIdProvider deviceIdProvider,
    required String brokerHost, // host only, e.g. "mqtt.oshhome.com"
    required int port,
    required this.tenantId,
    this.useWebSocket = false,
    this.secure = false,
    this.keepAliveSeconds = 30,
    this.autoReconnect = false,
  })  : _deviceIdProvider = deviceIdProvider,
        _client = MqttServerClient(brokerHost, "") {
    _client.logging(on: true);

    _client.port = port;
    _client.secure = secure;
    _client.useWebSocket = useWebSocket;
    _client.keepAlivePeriod = keepAliveSeconds;

    // If session-scoped: keep it OFF to avoid background reconnect with stale tokens.
    _client.autoReconnect = autoReconnect;

    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = (t) => _subscribedTopics.add(t);
  }

  final AppDeviceIdProvider _deviceIdProvider;
  final String tenantId;
  final bool useWebSocket;
  final bool secure;
  final int keepAliveSeconds;
  final bool autoReconnect;

  final MqttServerClient _client;

  final Map<String, StreamController<MqttJson>> _jsonCtrls = {};
  final Set<String> _jsonActiveFilters = {};
  final Set<String> _subscribedTopics = {};

  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _updatesSub;

  Future<void>? _connectInFlight;

  Future<String> _buildClientId(String userId) async {
    final deviceId = await _deviceIdProvider.getDeviceId();
    return 'u_${userId}_d_$deviceId';
  }

  @override
  bool get isConnected => _client.connectionStatus?.state == MqttConnectionState.connected;

  bool get _isConnecting => _client.connectionStatus?.state == MqttConnectionState.connecting;

  @override
  Future<void> connect({required String userId, required String token}) async {
    if (isConnected) {
      _attachUpdatesStream();
      return;
    }

    // Prevent concurrent handshakes.
    if (_connectInFlight != null) return _connectInFlight!;

    final f = _connectInternal(userId: userId, token: token);
    _connectInFlight = f;
    try {
      await f;
    } finally {
      _connectInFlight = null;
    }
  }

  Future<void> _connectInternal({
    required String userId,
    required String token,
  }) async {
    final clientId = await _buildClientId(userId);

    // Keep the same auth method as your previous working version.
    final connMsg = MqttConnectMessage().withClientIdentifier(clientId).authenticateAs(clientId, token);

    _client.connectionMessage = connMsg;

    try {
      await _client.connect();

      if (!isConnected) {
        throw StateError(
          'MQTT connect failed: ${_client.connectionStatus?.returnCode}',
        );
      }

      _attachUpdatesStream();
      _resubscribeAll();
    } catch (e, st) {
      await OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'Mqtt connect failed',
        context: {
          'host': _client.server,
          'port': _client.port,
          'secure': secure,
          'websocket': useWebSocket,
        },
      );

      // Best-effort cleanup.
      try {
        _client.disconnect();
      } catch (_) {}

      rethrow;
    }
  }

  @override
  Future<void> reconnect({required String userId, required String token}) async {
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
    } catch (_) {}
  }

  @override
  Stream<MqttJson> subscribeJson(String topicFilter, {int qos = 1}) {
    final ctrl = _jsonCtrls.putIfAbsent(topicFilter, () {
      if (isConnected && !_subscribedTopics.contains(topicFilter)) {
        _client.subscribe(topicFilter, _qosFromInt(qos));
        _subscribedTopics.add(topicFilter);
      }
      _jsonActiveFilters.add(topicFilter);

      return StreamController<MqttJson>.broadcast(
        onListen: () {
          if (isConnected && !_subscribedTopics.contains(topicFilter)) {
            _client.subscribe(topicFilter, _qosFromInt(qos));
            _subscribedTopics.add(topicFilter);
          }
        },
      );
    });

    return ctrl.stream;
  }

  @override
  Future<void> publishJson(
    String topic,
    Map<String, dynamic> payload, {
    int qos = 1,
    bool retain = false,
  }) async {
    if (!isConnected && _isConnecting) {
      await _waitForConnectCompletion();
    }

    if (!isConnected) {
      final error = StateError('MQTT not connected, cannot publish');
      await OshCrashReporter.logNonFatal(
        error,
        StackTrace.current,
        reason: 'Publish while disconnected',
        context: {'topic': topic},
      );
      return;
    }

    final builder = MqttClientPayloadBuilder()..addString(jsonEncode(payload));
    _client.publishMessage(
      topic,
      _qosFromInt(qos),
      builder.payload!,
      retain: retain,
    );
  }

  Future<void> _waitForConnectCompletion() async {
    const timeout = Duration(seconds: 5);
    const step = Duration(milliseconds: 100);
    final start = DateTime.now();

    while (_isConnecting && DateTime.now().difference(start) < timeout) {
      await Future.delayed(step);
    }
  }

  void _onConnected() {
    _attachUpdatesStream();
    _resubscribeAll();
  }

  void _onDisconnected() {
    // If autoReconnect=false, your coordinator controls reconnection.
  }

  void _attachUpdatesStream() {
    _updatesSub?.cancel();
    _updatesSub = _client.updates?.listen(
      _onUpdates,
      onError: (e, st) => OshCrashReporter.log('MQTT updates error: $e'),
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

  Map<String, dynamic> _decodePayload(String raw) {
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return Map<String, dynamic>.from(d);
      if (d is List) return {'data': d};
      return {'value': d};
    } catch (e, st) {
      OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'Failed to decode MQTT payload',
        context: {'raw': raw},
      );
      return {'raw': raw};
    }
  }

  bool _matchesTopicFilter(String filter, String topic) {
    final f = filter.split('/');
    final t = topic.split('/');

    for (int i = 0, j = 0; i < f.length; i++, j++) {
      final ft = f[i];
      if (ft == '#') return true;
      if (j >= t.length) return false;
      if (ft == '+') continue;
      if (ft != t[j]) return false;
    }
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
