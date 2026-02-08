// MQTT-backed ScheduleRepository using JSON-RPC + retained state.
// - State is delivered via retained notifications on state/schedule.
// - Commands use JSON-RPC requests on cmd/schedule with responses on /rsp.

import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/utils/latest_wins_gate.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/stream_waiters.dart';
import 'package:oshmobile/core/utils/superseded_exception.dart';
import 'package:oshmobile/features/schedule/data/schedule_jsonrpc_codec.dart';
import 'package:oshmobile/features/schedule/data/schedule_topics.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryMqtt implements ScheduleRepository {
  final DeviceMqttRepo _mqtt;
  final ScheduleTopics _topics;
  final Duration timeout;

  final Map<String, StreamController<CalendarSnapshot>> _ctrls = {};
  final Map<String, int> _refs = {};

  // One MQTT subscription per device for retained state.
  final Map<String, StreamSubscription> _stateSubs = {};

  // JSON-RPC responses (/rsp) fan-out, per device.
  final Map<String, StreamController<MapEntry<int, Map<String, dynamic>>>> _rspCtrls = {};
  final Map<String, StreamSubscription> _rspSubs = {};
  final Map<String, int> _rspSeq = {};

  // Last known snapshot per device.
  final Map<String, CalendarSnapshot> _last = {};

  // Latest-wins gate for mode updates.
  final LatestWinsGate _latest = LatestWinsGate();

  bool _disposed = false;

  ScheduleRepositoryMqtt(
    this._mqtt,
    this._topics, {
    this.timeout = const Duration(seconds: 6),
  });

  /// Best-effort cleanup when session scope is disposed.
  /// Not part of ScheduleRepository interface on purpose.
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
    _latest.clear();

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
  Future<CalendarSnapshot> fetchAll(String deviceId, {bool forceGet = false}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    if (!forceGet) {
      final cached = _last[deviceId];
      if (cached != null) return cached;

      try {
        final snap = await firstWithTimeout<CalendarSnapshot>(
          watchSnapshot(deviceId),
          timeout,
          timeoutMessage: 'Timeout waiting for schedule state',
        );
        return snap;
      } on TimeoutException {
        // Fallback: explicit JSON-RPC get.
      }
    }

    final reqId = newReqId();
    final resp = await _request(
      deviceId,
      method: ScheduleJsonRpcCodec.methodGet,
      reqId: reqId,
      data: null,
      timeoutMessage: 'Timeout waiting for schedule get response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap == null) {
      throw StateError('Invalid schedule response');
    }
    _emitSnapshot(deviceId, snap);
    return snap;
  }

  @override
  Future<void> saveAll(String deviceId, CalendarSnapshot snapshot, {String? reqId}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final prev = _last[deviceId];
    final id = reqId ?? newReqId();

    String method;
    Map<String, dynamic> data;

    if (prev == null) {
      method = ScheduleJsonRpcCodec.methodSet;
      data = ScheduleJsonRpcCodec.encodeBody(snapshot);
    } else {
      final modeChanged = prev.mode.id != snapshot.mode.id;
      final pointsPatch = _pointsPatch(prev.lists, snapshot.lists);

      if (!modeChanged && pointsPatch.isEmpty) return;

      method = ScheduleJsonRpcCodec.methodPatch;
      data = ScheduleJsonRpcCodec.encodePatch(
        mode: modeChanged ? snapshot.mode : null,
        points: pointsPatch.isNotEmpty ? pointsPatch : null,
      );
    }

    final resp = await _request(
      deviceId,
      method: method,
      reqId: id,
      data: data,
      timeoutMessage: 'Timeout waiting for schedule save response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap != null) _emitSnapshot(deviceId, snap);
  }

  @override
  Future<void> setMode(String deviceId, CalendarMode mode, {String? reqId}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final id = reqId ?? newReqId();
    final data = ScheduleJsonRpcCodec.encodePatch(mode: mode);
    final latest = _latest.start(_latestKey(deviceId, 'mode'));

    final resp = await _request(
      deviceId,
      method: ScheduleJsonRpcCodec.methodPatch,
      reqId: id,
      data: data,
      timeoutMessage: 'Timeout waiting for schedule mode response',
      cancel: latest.cancelled,
      cancelError: const SupersededException('Schedule mode superseded'),
    );

    if (!_latest.isCurrent(latest)) {
      throw const SupersededException('Schedule mode superseded');
    }

    final snap = _snapshotFromResponse(resp);
    if (snap != null) _emitSnapshot(deviceId, snap);
  }

  @override
  Stream<CalendarSnapshot> watchSnapshot(String deviceId) {
    if (_disposed) return Stream<CalendarSnapshot>.empty();

    final existing = _ctrls[deviceId];
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    late final StreamController<CalendarSnapshot> ctrl;
    ctrl = StreamController<CalendarSnapshot>.broadcast(
      onListen: () {
        _refs[deviceId] = (_refs[deviceId] ?? 0) + 1;
        if (_refs[deviceId]! > 1) return;

        _ensureStateSubscription(deviceId);

        final cached = _last[deviceId];
        if (cached != null) {
          ctrl.add(cached);
        }
      },
      onCancel: () async {
        _refs[deviceId] = (_refs[deviceId] ?? 1) - 1;
        if (_refs[deviceId]! <= 0) {
          _refs.remove(deviceId);
          final c = _ctrls.remove(deviceId);
          if (c != null && !c.isClosed) await c.close();
        }
      },
    );

    _ctrls[deviceId] = ctrl;
    return ctrl.stream;
  }

  // -------------------- MQTT subscriptions --------------------

  void _ensureStateSubscription(String deviceId) {
    if (_stateSubs.containsKey(deviceId)) return;

    final topic = _topics.state(deviceId);
    _stateSubs[deviceId] = _mqtt.subscribeJson(topic).listen((msg) {
      final notif = decodeJsonRpcNotification(msg.payload);
      if (notif == null) return;
      if (notif.method != ScheduleJsonRpcCodec.methodState) return;
      if (notif.meta.schema != ScheduleJsonRpcCodec.schema) return;

      final data = notif.data;
      if (data == null) return;

      final snap = ScheduleJsonRpcCodec.decodeBody(data);
      if (snap == null) return;

      _emitSnapshot(deviceId, snap);
    });
  }

  void _ensureRspSubscription(String deviceId) {
    if (_rspSubs.containsKey(deviceId)) return;

    final topic = _topics.rsp(deviceId);
    _rspSubs[deviceId] = _mqtt.subscribeJson(topic).listen((msg) {
      final nextSeq = (_rspSeq[deviceId] ?? 0) + 1;
      _rspSeq[deviceId] = nextSeq;

      final ctrl = _rspCtrls[deviceId];
      if (ctrl != null && !ctrl.isClosed) {
        ctrl.add(MapEntry(nextSeq, msg.payload));
      }
    });
  }

  Stream<MapEntry<int, Map<String, dynamic>>> _rspEvents(String deviceId) {
    final existing = _rspCtrls[deviceId];
    if (existing != null && !existing.isClosed) return existing.stream;

    final ctrl = StreamController<MapEntry<int, Map<String, dynamic>>>.broadcast(
      onListen: () {
        _ensureRspSubscription(deviceId);
      },
    );

    _rspCtrls[deviceId] = ctrl;
    return ctrl.stream;
  }

  // -------------------- JSON-RPC helpers --------------------

  void _emitSnapshot(String deviceId, CalendarSnapshot snap) {
    _last[deviceId] = snap;
    final ctrl = _ctrls[deviceId];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(snap);
    }
  }

  JsonRpcMeta _meta() => JsonRpcMeta(
        schema: ScheduleJsonRpcCodec.schema,
        src: 'app',
        ts: DateTime.now().millisecondsSinceEpoch,
      );

  String _latestKey(String deviceId, String op) => '$deviceId:$op';

  Future<JsonRpcResponse> _request(
    String deviceId, {
    required String method,
    required String reqId,
    required Map<String, dynamic>? data,
    required String timeoutMessage,
    Future<void>? cancel,
    Object? cancelError,
  }) async {
    final cmdTopic = _topics.cmd(deviceId);

    _ensureRspSubscription(deviceId);
    final events = _rspEvents(deviceId);

    final startSeq = _rspSeq[deviceId] ?? 0;
    final waitRsp = firstWhereWithTimeout<MapEntry<int, Map<String, dynamic>>>(
      events,
      (e) => e.key > startSeq && e.value['id']?.toString() == reqId,
      timeout,
      timeoutMessage: timeoutMessage,
      cancel: cancel,
      cancelError: cancelError,
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
      throw StateError('Schedule request failed: ${resp.error!.message} (code ${resp.error!.code})');
    }

    return resp;
  }

  CalendarSnapshot? _snapshotFromResponse(JsonRpcResponse resp) {
    final data = resp.data;
    if (data == null) return null;

    if (resp.meta != null && resp.meta!.schema != ScheduleJsonRpcCodec.schema) {
      return null;
    }

    return ScheduleJsonRpcCodec.decodeBody(data);
  }

  // -------------------- Diff helpers --------------------

  Map<CalendarMode, List<SchedulePoint>> _pointsPatch(
    Map<CalendarMode, List<SchedulePoint>> prev,
    Map<CalendarMode, List<SchedulePoint>> next,
  ) {
    final out = <CalendarMode, List<SchedulePoint>>{};
    for (final m in CalendarMode.all) {
      final a = prev[m] ?? const <SchedulePoint>[];
      final b = next[m] ?? const <SchedulePoint>[];
      if (!_listsEqual(a, b)) out[m] = b;
    }
    return out;
  }

  bool _listsEqual(List<SchedulePoint> a, List<SchedulePoint> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_pointEquals(a[i], b[i])) return false;
    }
    return true;
  }

  bool _pointEquals(SchedulePoint x, SchedulePoint y) {
    return x.daysMask == y.daysMask &&
        x.time.hour == y.time.hour &&
        x.time.minute == y.time.minute &&
        x.min == y.min &&
        x.max == y.max;
  }
}
