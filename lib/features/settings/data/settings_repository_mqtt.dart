import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/stream_waiters.dart';
import 'package:oshmobile/features/settings/data/settings_jsonrpc_codec.dart';
import 'package:oshmobile/features/settings/data/settings_topics.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryMqtt implements SettingsRepository {
  final DeviceMqttRepo _mqtt;
  final SettingsTopics _topics;
  final Duration timeout;

  // Snapshot watchers (UI).
  final Map<String, StreamController<MapEntry<String?, SettingsSnapshot>>> _ctrls = {};
  final Map<String, int> _refs = {};

  // One MQTT subscription per device for retained state.
  final Map<String, StreamSubscription> _stateSubs = {};

  // JSON-RPC responses (/rsp) fan-out, per device.
  final Map<String, StreamController<MapEntry<int, Map<String, dynamic>>>> _rspCtrls = {};
  final Map<String, StreamSubscription> _rspSubs = {};
  final Map<String, int> _rspSeq = {};

  // Last known snapshot per device.
  final Map<String, SettingsSnapshot> _last = {};

  bool _disposed = false;

  SettingsRepositoryMqtt(
    this._mqtt,
    this._topics, {
    this.timeout = const Duration(seconds: 6),
  });

  /// Best-effort cleanup when session scope is disposed.
  /// Not part of SettingsRepository interface on purpose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final stateSubs = _stateSubs.values.toList(growable: false);
    final rspSubs = _rspSubs.values.toList(growable: false);
    final ctrls = _ctrls.values.toList(growable: false);
    final rspCtrls = _rspCtrls.values.toList(growable: false);

    _stateSubs.clear();
    _rspSubs.clear();
    _ctrls.clear();
    _rspCtrls.clear();
    _refs.clear();
    _rspSeq.clear();
    _last.clear();

    for (final s in stateSubs) {
      try {
        await s.cancel();
      } catch (_) {}
    }
    for (final s in rspSubs) {
      try {
        await s.cancel();
      } catch (_) {}
    }
    for (final c in ctrls) {
      try {
        if (!c.isClosed) await c.close();
      } catch (_) {}
    }
    for (final c in rspCtrls) {
      try {
        if (!c.isClosed) await c.close();
      } catch (_) {}
    }
  }

  // -------------------- Public API --------------------

  @override
  Future<SettingsSnapshot> fetchAll(String deviceSn, {bool forceGet = false}) async {
    if (_disposed) throw StateError('SettingsRepositoryMqtt is disposed');

    if (!forceGet) {
      final cached = _last[deviceSn];
      if (cached != null) return cached;

      try {
        final entry = await firstWithTimeout<MapEntry<String?, SettingsSnapshot>>(
          watchSnapshot(deviceSn),
          timeout,
          timeoutMessage: 'Timeout waiting for settings state',
        );
        return entry.value;
      } on TimeoutException {
        // Fallback: explicit JSON-RPC get.
      }
    }

    final reqId = newReqId();
    final resp = await _request(
      deviceSn,
      method: SettingsJsonRpcCodec.methodGet,
      reqId: reqId,
      data: null,
      timeoutMessage: 'Timeout waiting for settings get response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap == null) {
      throw StateError('Invalid settings response');
    }
    _emitSnapshot(deviceSn, snap, appliedReqId: null);
    return snap;
  }

  @override
  Future<void> saveAll(
    String deviceSn,
    SettingsSnapshot snapshot, {
    String? reqId,
  }) async {
    if (_disposed) throw StateError('SettingsRepositoryMqtt is disposed');

    final id = reqId ?? newReqId();
    final data = SettingsJsonRpcCodec.encodeBody(snapshot);

    final resp = await _request(
      deviceSn,
      method: SettingsJsonRpcCodec.methodSet,
      reqId: id,
      data: data,
      timeoutMessage: 'Timeout waiting for settings save response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap != null) _emitSnapshot(deviceSn, snap, appliedReqId: id);
  }

  @override
  Stream<MapEntry<String?, SettingsSnapshot>> watchSnapshot(String deviceSn) {
    if (_disposed) return Stream<MapEntry<String?, SettingsSnapshot>>.empty();

    final existing = _ctrls[deviceSn];
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    late final StreamController<MapEntry<String?, SettingsSnapshot>> ctrl;

    ctrl = StreamController<MapEntry<String?, SettingsSnapshot>>.broadcast(
      onListen: () {
        _refs[deviceSn] = (_refs[deviceSn] ?? 0) + 1;
        if (_refs[deviceSn]! > 1) return;

        _ensureStateSubscription(deviceSn);

        final cached = _last[deviceSn];
        if (cached != null) {
          ctrl.add(MapEntry(null, cached));
        }
      },
      onCancel: () async {
        _refs[deviceSn] = (_refs[deviceSn] ?? 1) - 1;
        if (_refs[deviceSn]! <= 0) {
          _refs.remove(deviceSn);

          final c = _ctrls.remove(deviceSn);
          if (c != null && !c.isClosed) {
            await c.close();
          }
        }
      },
    );

    _ctrls[deviceSn] = ctrl;
    return ctrl.stream;
  }

  // -------------------- MQTT subscriptions --------------------

  void _ensureStateSubscription(String deviceSn) {
    if (_stateSubs.containsKey(deviceSn)) return;

    final topic = _topics.state(deviceSn);
    _stateSubs[deviceSn] = _mqtt.subscribeJson(topic).listen((msg) {
      final notif = decodeJsonRpcNotification(msg.payload);
      if (notif == null) return;
      if (notif.method != SettingsJsonRpcCodec.methodState) return;
      if (notif.meta.schema != SettingsJsonRpcCodec.schema) return;

      final data = notif.data;
      if (data == null) return;

      final snap = SettingsJsonRpcCodec.decodeBody(data);
      _emitSnapshot(deviceSn, snap, appliedReqId: null);
    });
  }

  void _ensureRspSubscription(String deviceSn) {
    if (_rspSubs.containsKey(deviceSn)) return;

    final topic = _topics.rsp(deviceSn);
    _rspSubs[deviceSn] = _mqtt.subscribeJson(topic).listen((msg) {
      final nextSeq = (_rspSeq[deviceSn] ?? 0) + 1;
      _rspSeq[deviceSn] = nextSeq;

      final ctrl = _rspCtrls[deviceSn];
      if (ctrl != null && !ctrl.isClosed) {
        ctrl.add(MapEntry(nextSeq, msg.payload));
      }
    });
  }

  Stream<MapEntry<int, Map<String, dynamic>>> _rspEvents(String deviceSn) {
    final existing = _rspCtrls[deviceSn];
    if (existing != null && !existing.isClosed) return existing.stream;

    final ctrl = StreamController<MapEntry<int, Map<String, dynamic>>>.broadcast(
      onListen: () {
        _ensureRspSubscription(deviceSn);
      },
    );

    _rspCtrls[deviceSn] = ctrl;
    return ctrl.stream;
  }

  // -------------------- JSON-RPC helpers --------------------

  void _emitSnapshot(String deviceSn, SettingsSnapshot snap, {String? appliedReqId}) {
    _last[deviceSn] = snap;
    final ctrl = _ctrls[deviceSn];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(MapEntry(appliedReqId, snap));
    }
  }

  JsonRpcMeta _meta() => JsonRpcMeta(
        schema: SettingsJsonRpcCodec.schema,
        src: 'app',
        ts: DateTime.now().millisecondsSinceEpoch,
      );

  Future<JsonRpcResponse> _request(
    String deviceSn, {
    required String method,
    required String reqId,
    required Map<String, dynamic>? data,
    required String timeoutMessage,
  }) async {
    final cmdTopic = _topics.cmd(deviceSn);

    _ensureRspSubscription(deviceSn);
    final events = _rspEvents(deviceSn);

    final startSeq = _rspSeq[deviceSn] ?? 0;
    final waitRsp = firstWhereWithTimeout<MapEntry<int, Map<String, dynamic>>>(
      events,
      (e) => e.key > startSeq && e.value['id']?.toString() == reqId,
      timeout,
      timeoutMessage: timeoutMessage,
    );

    final payload = buildJsonRpcRequest(
      id: reqId,
      method: method,
      meta: _meta(),
      data: data,
    );

    await _mqtt.publishJson(cmdTopic, payload);

    final ev = await waitRsp;
    final resp = decodeJsonRpcResponse(ev.value);
    if (resp == null) throw StateError('Invalid JSON-RPC response');

    if (resp.error != null) {
      throw StateError('Settings request failed: ${resp.error!.message} (code ${resp.error!.code})');
    }

    return resp;
  }

  SettingsSnapshot? _snapshotFromResponse(JsonRpcResponse resp) {
    final data = resp.data;
    if (data == null) return null;

    if (resp.meta != null && resp.meta!.schema != SettingsJsonRpcCodec.schema) {
      return null;
    }

    return SettingsJsonRpcCodec.decodeBody(data);
  }
}
