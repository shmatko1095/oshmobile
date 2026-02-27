import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/mqtt/app_device_id_provider.dart';

import 'device_mqtt_repo.dart';

/// Transport-only MQTT repo.
///
/// Clean semantics:
/// - connect/reconnect/disconnect do NOT close JSON controllers
///   (so reconnect will not break listeners).
/// - disposeSession() closes everything and must be called ONLY on logout/session end.
/// - publishJson does not throw when disconnected (prevents unhandled async errors
///   when callers use unawaited()).
///
/// Subscription semantics:
/// - subscribeJson() is reference-counted by stream subscription lifetime.
///   When the last listener cancels, we unsubscribe from broker and dispose
///   the internal filter controller.
///
/// This prevents unbounded growth of topic filters after screen switches.
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
    this.connectTimeout = const Duration(seconds: 10),
    this.publishWaitTimeout = const Duration(seconds: 6),
  })  : _deviceIdProvider = deviceIdProvider,
        _client = MqttServerClient(brokerHost, "") {
    _client.logging(on: true);

    _client.port = port;
    _client.secure = secure;
    _client.useWebSocket = useWebSocket;
    _client.keepAlivePeriod = keepAliveSeconds;

    // If you use token-based auth, consider managing reconnect in your session manager,
    // because autoReconnect will retry with the same credentials.
    _client.autoReconnect = autoReconnect;

    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;
  }

  final AppDeviceIdProvider _deviceIdProvider;
  final String tenantId;
  final bool useWebSocket;
  final bool secure;
  final int keepAliveSeconds;
  final bool autoReconnect;
  final Duration connectTimeout;
  final Duration publishWaitTimeout;

  final MqttServerClient _client;

  // Broadcast connection events so UI/state layer can reflect *real* transport state.
  final StreamController<DeviceMqttConnEvent> _connCtrl =
      StreamController<DeviceMqttConnEvent>.broadcast();
  DeviceMqttConnState _connState = DeviceMqttConnState.disconnected;

  // One controller per topic filter.
  final Map<String, StreamController<MqttJson>> _jsonCtrls = {};

  // Reference counter for topic filters (one ref per subscribeJson() listener).
  final Map<String, int> _filterRefs = {};

  // QoS per filter (we keep the max seen).
  final Map<String, int> _filterQos = {};

  // Optional: keep for debugging/telemetry only.
  final Set<String> _ackSubscribed = {};

  StreamSubscription<List<MqttReceivedMessage<MqttMessage?>>>? _updatesSub;
  Future<void>? _rebindUpdatesInFlight;
  bool _updatesRebindQueued = false;

  Future<void>? _connectInFlight;

  // A gate that completes when we are connected (used to await short publish-before-connect races).
  Completer<void> _connectedGate = Completer<void>();

  @override
  Stream<DeviceMqttConnEvent> get connEvents => _connCtrl.stream;

  Future<String> _buildClientId(String userId) async {
    final deviceId = await _deviceIdProvider.getDeviceId();
    return 'u_${userId}_d_$deviceId';
  }

  @override
  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  bool get _isConnecting =>
      _client.connectionStatus?.state == MqttConnectionState.connecting;

  // ------------------- Connection lifecycle -------------------

  @override
  Future<void> connect({required String userId, required String token}) async {
    if (isConnected) {
      // Ensure updates subscription is attached (defensive).
      await _attachUpdatesStream();
      return;
    }

    // Prevent parallel handshakes from different callers.
    if (_connectInFlight != null) {
      await _connectInFlight;
      return;
    }

    final fut = _connectInternal(userId: userId, token: token);
    _connectInFlight = fut;
    try {
      await fut;
    } finally {
      _connectInFlight = null;
    }
  }

  Future<void> _connectInternal(
      {required String userId, required String token}) async {
    _emitConn(DeviceMqttConnState.connecting);
    final clientId = await _buildClientId(userId);

    // IMPORTANT: broker auth style must match your backend/broker config.
    // Here: username = clientId, password = token.
    final connMsg = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .authenticateAs(clientId, token)
        .startClean(); // clean session -> always resubscribe after connect

    _client.clientIdentifier = clientId;
    _client.connectionMessage = connMsg;

    try {
      await _client.connect().timeout(connectTimeout);
    } on TimeoutException catch (e, st) {
      _emitConn(DeviceMqttConnState.disconnected, error: e);
      await OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'MQTT connect() timed out',
        context: {
          'clientId': clientId,
          'timeoutMs': connectTimeout.inMilliseconds
        },
      );
      try {
        _client.disconnect();
      } catch (_) {}
      rethrow;
    } catch (e, st) {
      _emitConn(DeviceMqttConnState.disconnected, error: e);
      await OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'MQTT connect() threw',
        context: {'clientId': clientId},
      );
      try {
        _client.disconnect();
      } catch (_) {}
      rethrow;
    }

    if (!isConnected) {
      final rc = _client.connectionStatus?.returnCode.toString();
      _emitConn(DeviceMqttConnState.disconnected,
          error: StateError('MQTT connect rejected: $rc'));
      await OshCrashReporter.logNonFatal(
        'MQTT connect rejected: $rc',
        StackTrace.current,
        reason: 'MQTT connect() not accepted',
        context: {'clientId': clientId},
      );
      try {
        _client.disconnect();
      } catch (_) {}
      throw StateError('MQTT connect failed: $rc');
    }

    _markConnected();
    _emitConn(DeviceMqttConnState.connected);
    await _attachUpdatesStream();
    _resubscribeAllActiveFilters();
  }

  @override
  Future<void> reconnect(
      {required String userId, required String token}) async {
    // Transport reconnect: keep controllers alive.
    try {
      _client.disconnect();
    } catch (_) {}
    _markDisconnected();
    _emitConn(DeviceMqttConnState.disconnected);
    await connect(userId: userId, token: token);
  }

  @override
  Future<void> disconnect() async {
    // Transport disconnect: keep controllers alive.
    final rebinding = _rebindUpdatesInFlight;
    if (rebinding != null) {
      try {
        await rebinding;
      } catch (_) {}
    }

    try {
      await _updatesSub?.cancel();
      _updatesSub = null;
    } catch (_) {}

    try {
      _client.disconnect();
    } catch (_) {}

    _markDisconnected();
    _emitConn(DeviceMqttConnState.disconnected);
  }

  @override
  Future<void> disposeSession() async {
    // Session end (logout): close controllers + clear all local state.
    await disconnect();

    final ctrls = _jsonCtrls.values.toList(growable: false);
    _jsonCtrls.clear();
    _filterRefs.clear();
    _filterQos.clear();
    _ackSubscribed.clear();

    for (final c in ctrls) {
      try {
        await c.close();
      } catch (_) {}
    }

    try {
      await _connCtrl.close();
    } catch (_) {}
  }

  // ------------------- Subscriptions -------------------

  @override
  Stream<MqttJson> subscribeJson(String topicFilter, {int qos = 1}) {
    // A new stream per caller so we can ref-count on cancel.
    return Stream<MqttJson>.multi((controller) {
      _acquireFilter(topicFilter, qos: qos);

      final base = _jsonCtrls[topicFilter];
      if (base == null) {
        controller.addError(
            StateError('Failed to acquire MQTT filter: $topicFilter'));
        controller.close();
        return;
      }

      late final StreamSubscription sub;
      sub = base.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
        cancelOnError: false,
      );

      controller.onCancel = () async {
        await sub.cancel();
        _releaseFilter(topicFilter);
      };
    });
  }

  void _acquireFilter(String topicFilter, {required int qos}) {
    final nextRefs = (_filterRefs[topicFilter] ?? 0) + 1;
    _filterRefs[topicFilter] = nextRefs;

    final prevQos = _filterQos[topicFilter] ?? qos;
    final nextQos = max(prevQos, qos);
    _filterQos[topicFilter] = nextQos;

    _jsonCtrls.putIfAbsent(
        topicFilter, () => StreamController<MqttJson>.broadcast());

    // If already connected, subscribe immediately.
    // If QoS was upgraded, re-subscribe with the new QoS (best-effort).
    if (isConnected && (nextRefs == 1 || nextQos != prevQos)) {
      _client.subscribe(topicFilter, _qosFromInt(nextQos));
    }
  }

  void _releaseFilter(String topicFilter) {
    final cur = _filterRefs[topicFilter];
    if (cur == null) return;

    final next = cur - 1;
    if (next > 0) {
      _filterRefs[topicFilter] = next;
      return;
    }

    _filterRefs.remove(topicFilter);
    _filterQos.remove(topicFilter);

    // Broker unsubscribe is best-effort.
    if (isConnected) {
      try {
        _client.unsubscribe(topicFilter);
      } catch (_) {}
    }

    _ackSubscribed.remove(topicFilter);

    final ctrl = _jsonCtrls.remove(topicFilter);
    if (ctrl != null && !ctrl.isClosed) {
      unawaited(ctrl.close());
    }
  }

  void _resubscribeAllActiveFilters() {
    // With startClean(), broker forgets all subscriptions -> must resubscribe always.
    _ackSubscribed.clear();

    if (!isConnected) return;
    if (_filterRefs.isEmpty) return;

    for (final entry in _filterRefs.entries) {
      final filter = entry.key;
      final qos = _filterQos[filter] ?? 1;
      _client.subscribe(filter, _qosFromInt(qos));
    }
  }

  // ------------------- Publish -------------------

  @override
  Future<bool> publishJson(
    String topic,
    Map<String, dynamic> payload, {
    int qos = 1,
    bool retain = false,
  }) async {
    // If connect/reconnect is in-flight, wait briefly.
    if (!isConnected && (_isConnecting || _connectInFlight != null)) {
      try {
        await Future.any([
          _connectInFlight ?? _waitForConnectCompletion(),
          Future.delayed(publishWaitTimeout),
        ]);
      } catch (_) {}
    }

    if (!isConnected) {
      OshCrashReporter.log('MQTT publish skipped (disconnected). topic=$topic');
      return false;
    }

    try {
      final builder = MqttClientPayloadBuilder()
        ..addString(jsonEncode(payload));
      _client.publishMessage(topic, _qosFromInt(qos), builder.payload!,
          retain: retain);
      return true;
    } catch (e, st) {
      // Do NOT rethrow: some callers may use unawaited().
      unawaited(OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'MQTT publish failed',
        context: {'topic': topic},
      ));
      return false;
    }
  }

  // ------------------- Incoming messages fan-out -------------------

  Future<void> _attachUpdatesStream() {
    _updatesRebindQueued = true;
    final inFlight = _rebindUpdatesInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    _rebindUpdatesInFlight = () async {
      while (_updatesRebindQueued) {
        _updatesRebindQueued = false;

        final prev = _updatesSub;
        _updatesSub = null;
        if (prev != null) {
          try {
            await prev.cancel();
          } catch (_) {}
        }

        _updatesSub = _client.updates?.listen(
          _onUpdates,
          onError: (e, st) => OshCrashReporter.log('MQTT updates error: $e'),
        );
      }
    }()
        .whenComplete(() {
      _rebindUpdatesInFlight = null;
    });

    return _rebindUpdatesInFlight!;
  }

  void _onUpdates(List<MqttReceivedMessage<MqttMessage?>> events) {
    if (_jsonCtrls.isEmpty) return;

    for (final evt in events) {
      final topic = evt.topic;
      final msg = evt.payload;
      if (msg is! MqttPublishMessage) continue;

      final raw = MqttPublishPayload.bytesToStringAsString(msg.payload.message);
      final decoded = _decodePayload(raw);
      final item = MqttJson(topic, decoded);

      for (final entry in _jsonCtrls.entries) {
        final filter = entry.key;
        final ctrl = entry.value;
        if (ctrl.isClosed) continue;

        if (_matchesTopicFilter(filter, topic)) {
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
      unawaited(OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'MQTT JSON decode failed',
        context: {'raw': raw},
      ));
      return {'raw': raw};
    }
  }

  bool _matchesTopicFilter(String filter, String topic) {
    final f = filter.split('/');
    final t = topic.split('/');

    for (int i = 0, j = 0; i < f.length; i++, j++) {
      final ft = f[i];
      if (ft == '#') return true; // multi-level wildcard matches the rest
      if (j >= t.length) return false; // topic shorter than filter
      if (ft == '+') continue; // single-level wildcard
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

  Future<void> _waitForConnectCompletion() async {
    const timeout = Duration(seconds: 6);
    const step = Duration(milliseconds: 100);
    final start = DateTime.now();

    while (_isConnecting && DateTime.now().difference(start) < timeout) {
      await Future.delayed(step);
    }
  }

  // ------------------- Client callbacks -------------------

  void _onConnected() {
    _markConnected();
    _emitConn(DeviceMqttConnState.connected);
    unawaited(_attachUpdatesStream());
    _resubscribeAllActiveFilters();
  }

  void _onDisconnected() {
    _markDisconnected();
    _emitConn(DeviceMqttConnState.disconnected);
    // If autoReconnect=true, mqtt_client will reconnect with the same credentials.
    // After auto reconnect, onConnected() will resubscribe filters again.
  }

  void _onSubscribed(String topic) {
    _ackSubscribed.add(topic);
  }

  void _markConnected() {
    if (_connectedGate.isCompleted) return;
    _connectedGate.complete();
  }

  void _markDisconnected() {
    _connectedGate = Completer<void>();
    _ackSubscribed.clear();
  }

  void _emitConn(DeviceMqttConnState next, {Object? error}) {
    // Deduplicate same-state events unless we have an error payload.
    if (next == _connState && error == null) return;
    _connState = next;

    if (_connCtrl.isClosed) return;
    try {
      _connCtrl.add(DeviceMqttConnEvent(state: next, error: error));
    } catch (_) {
      // Never throw to the Zone from infra.
    }
  }
}
