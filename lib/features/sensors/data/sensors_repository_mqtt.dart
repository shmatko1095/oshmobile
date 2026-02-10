import 'dart:async';

import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/stream_waiters.dart';
import 'package:oshmobile/features/sensors/data/sensors_jsonrpc_codec.dart';
import 'package:oshmobile/features/sensors/data/sensors_payload_validator.dart';
import 'package:oshmobile/features/sensors/data/sensors_topics.dart';
import 'package:oshmobile/features/sensors/domain/repositories/sensors_repository.dart';

class SensorsRepositoryMqtt implements SensorsRepository {
  final JsonRpcClient _jrpc;
  final SensorsTopics _topics;
  final String _deviceSn;
  final Duration timeout;

  StreamController<SensorsState>? _ctrl;
  int _refs = 0;

  StreamSubscription? _stateSub;

  SensorsState? _last;

  bool _disposed = false;

  SensorsRepositoryMqtt(
    this._jrpc,
    this._topics,
    this._deviceSn, {
    this.timeout = const Duration(seconds: 6),
  });

  /// Best-effort cleanup when device scope is disposed.
  /// Not part of SensorsRepository interface on purpose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final stateSub = _stateSub;
    final ctrl = _ctrl;

    _stateSub = null;
    _ctrl = null;
    _refs = 0;
    _last = null;

    if (stateSub != null) {
      try {
        await stateSub.cancel();
      } catch (_) {}
    }
    if (ctrl != null) {
      try {
        if (!ctrl.isClosed) await ctrl.close();
      } catch (_) {}
    }
  }

  @override
  Future<SensorsState> fetchAll({bool forceGet = false}) async {
    if (_disposed) throw StateError('SensorsRepositoryMqtt is disposed');

    if (!forceGet) {
      final cached = _last;
      if (cached != null) return cached;

      try {
        final snap = await firstWithTimeout<SensorsState>(
          watchState(),
          timeout,
          timeoutMessage: 'Timeout waiting for sensors state',
        );
        return snap;
      } on TimeoutException {
        // Fallback: explicit JSON-RPC get.
      }
    }

    final reqId = newReqId();
    final resp = await _request(
      method: SensorsJsonRpcCodec.methodGet,
      reqId: reqId,
      data: null,
      timeoutMessage: 'Timeout waiting for sensors get response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap == null) {
      throw StateError('Invalid sensors response');
    }
    _emitSnapshot(snap);
    return snap;
  }

  @override
  Future<void> saveAll(SensorsSetPayload payload, {String? reqId}) async {
    if (_disposed) throw StateError('SensorsRepositoryMqtt is disposed');

    final id = reqId ?? newReqId();
    final data = payload.toJson();
    if (!validateSensorsSetPayload(data)) {
      throw FormatException('Invalid sensors.set payload');
    }

    final resp = await _request(
      method: SensorsJsonRpcCodec.methodSet,
      reqId: id,
      data: data,
      timeoutMessage: 'Timeout waiting for sensors set response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap != null) _emitSnapshot(snap);
  }

  @override
  Future<void> patch(SensorsPatch patch, {String? reqId}) async {
    if (_disposed) throw StateError('SensorsRepositoryMqtt is disposed');

    final id = reqId ?? newReqId();
    final data = patch.toJson();
    if (!validateSensorsPatchPayload(data)) {
      throw FormatException('Invalid sensors.patch payload');
    }

    final resp = await _request(
      method: SensorsJsonRpcCodec.methodPatch,
      reqId: id,
      data: data,
      timeoutMessage: 'Timeout waiting for sensors patch response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap != null) _emitSnapshot(snap);
  }

  @override
  Stream<SensorsState> watchState() {
    if (_disposed) return Stream<SensorsState>.empty();

    final existing = _ctrl;
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    late final StreamController<SensorsState> ctrl;

    ctrl = StreamController<SensorsState>.broadcast(
      onListen: () {
        _refs += 1;
        if (_refs > 1) return;

        _ensureStateSubscription();

        final cached = _last;
        if (cached != null) {
          ctrl.add(cached);
        }
      },
      onCancel: () async {
        _refs -= 1;
        if (_refs <= 0) {
          _refs = 0;
          final c = _ctrl;
          _ctrl = null;
          if (c != null && !c.isClosed) {
            await c.close();
          }
        }
      },
    );

    _ctrl = ctrl;
    return ctrl.stream;
  }

  void _ensureStateSubscription() {
    if (_stateSub != null) return;

    final topic = _topics.state(_deviceSn);
    _stateSub = _jrpc
        .notifications(
          topic,
          method: SensorsJsonRpcCodec.methodState,
          schema: SensorsJsonRpcCodec.schema,
        )
        .listen((notif) {
      final data = notif.data;
      if (data == null) return;

      final snap = SensorsState.fromJson(data);
      if (snap == null) return;

      _emitSnapshot(snap);
    });
  }

  void _emitSnapshot(SensorsState snap) {
    _last = snap;
    final ctrl = _ctrl;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(snap);
    }
  }

  JsonRpcMeta _meta() => JsonRpcMeta(
        schema: SensorsJsonRpcCodec.schema,
        src: 'app',
        ts: DateTime.now().millisecondsSinceEpoch,
      );

  Future<JsonRpcResponse> _request({
    required String method,
    required String reqId,
    required Map<String, dynamic>? data,
    required String timeoutMessage,
  }) async {
    return _jrpc.request(
      cmdTopic: _topics.cmd(_deviceSn),
      method: method,
      meta: _meta(),
      reqId: reqId,
      data: data,
      domain: SensorsJsonRpcCodec.domain,
      timeout: timeout,
      timeoutMessage: timeoutMessage,
    );
  }

  SensorsState? _snapshotFromResponse(JsonRpcResponse resp) {
    final data = resp.data;
    if (data == null) return null;

    if (resp.meta != null && resp.meta!.schema != SensorsJsonRpcCodec.schema) {
      return null;
    }

    return SensorsState.fromJson(data);
  }
}
