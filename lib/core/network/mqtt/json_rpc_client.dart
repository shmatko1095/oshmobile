import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_errors.dart';
import 'package:oshmobile/core/utils/stream_waiters.dart';

/// Shared JSON-RPC transport helper for MQTT-based domains.
///
/// - Manages a single /rsp subscription per device.
/// - Builds and sends JSON-RPC requests.
/// - Correlates responses by `id`.
class JsonRpcClient {
  JsonRpcClient(
      {required DeviceMqttRepo mqtt, required String rspTopic, this.defaultTimeout = const Duration(seconds: 6), d})
      : _mqtt = mqtt,
        _rspTopic = rspTopic;

  final DeviceMqttRepo _mqtt;
  final String _rspTopic;
  final Duration defaultTimeout;

  StreamController<MapEntry<int, Map<String, dynamic>>>? _rspCtrl;
  StreamSubscription? _rspSub;
  int _rspSeq = 0;
  bool _disposed = false;

  bool get isConnected => _mqtt.isConnected;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final rspSub = _rspSub;
    final rspCtrl = _rspCtrl;

    _rspSub = null;
    _rspCtrl = null;
    _rspSeq = 0;

    if (rspSub != null) {
      try {
        await rspSub.cancel();
      } catch (_) {}
    }
    if (rspCtrl != null) {
      try {
        if (!rspCtrl.isClosed) await rspCtrl.close();
      } catch (_) {}
    }
  }

  Stream<JsonRpcNotification> notifications(
    String topicFilter, {
    String? method,
    String? schema,
  }) {
    return _mqtt
        .subscribeJson(topicFilter)
        .map((msg) => decodeJsonRpcNotification(msg.payload))
        .where((n) => n != null)
        .cast<JsonRpcNotification>()
        .where((n) {
      if (method != null && n.method != method) return false;
      if (schema != null && n.meta.schema != schema) return false;
      return true;
    });
  }

  Future<JsonRpcResponse> request({
    required String cmdTopic,
    required String method,
    required JsonRpcMeta meta,
    required String reqId,
    required Map<String, dynamic>? data,
    String? domain,
    Duration? timeout,
    String? timeoutMessage,
    Future<void>? cancel,
    Object? cancelError,
    bool throwOnError = true,
  }) async {
    if (_disposed) throw StateError('JsonRpcClient is disposed');

    _ensureRspSubscription();
    final events = _rspEvents();

    final startSeq = _rspSeq;
    final waitRsp = firstWhereWithTimeout<MapEntry<int, Map<String, dynamic>>>(
      events,
      (e) => e.key > startSeq && e.value['id']?.toString() == reqId,
      timeout ?? defaultTimeout,
      timeoutMessage: timeoutMessage ?? 'Timeout waiting for JSON-RPC response',
      cancel: cancel,
      cancelError: cancelError,
    );

    final payload = buildJsonRpcRequest(
      id: reqId,
      method: method,
      meta: meta,
      data: data,
    );

    await _mqtt.publishJson(cmdTopic, payload);

    final ev = await waitRsp;
    final resp = decodeJsonRpcResponse(ev.value);
    if (resp == null) throw StateError('Invalid JSON-RPC response');

    if (resp.error != null && throwOnError) {
      final err = resp.error!;
      throw mapJsonRpcError(err.code, err.message, domain: domain);
    }

    return resp;
  }

  void _ensureRspSubscription() {
    if (_rspSub != null) return;

    _rspSub = _mqtt.subscribeJson(_rspTopic).listen((msg) {
      final nextSeq = _rspSeq + 1;
      _rspSeq = nextSeq;

      final ctrl = _rspCtrl;
      if (ctrl != null && !ctrl.isClosed) {
        ctrl.add(MapEntry(nextSeq, msg.payload));
      }
    });
  }

  Stream<MapEntry<int, Map<String, dynamic>>> _rspEvents() {
    final existing = _rspCtrl;
    if (existing != null && !existing.isClosed) return existing.stream;

    final ctrl = StreamController<MapEntry<int, Map<String, dynamic>>>.broadcast(
      onListen: _ensureRspSubscription,
    );

    _rspCtrl = ctrl;
    return ctrl.stream;
  }
}
