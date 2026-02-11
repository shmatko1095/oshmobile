// MQTT-backed ScheduleRepository using JSON-RPC + retained state.
// - State is delivered via retained notifications on state/schedule.
// - Commands use JSON-RPC requests on cmd/schedule with responses on /rsp.

import 'dart:async';

import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
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
  final JsonRpcClient _jrpc;
  final ScheduleTopics _topics;
  final String _deviceSn;
  final Duration timeout;

  StreamController<CalendarSnapshot>? _ctrl;
  int _refs = 0;

  StreamSubscription? _stateSub;

  CalendarSnapshot? _last;

  // Latest-wins gate for mode updates.
  final LatestWinsGate _latest = LatestWinsGate();

  bool _disposed = false;

  ScheduleRepositoryMqtt(
    this._jrpc,
    this._topics,
    this._deviceSn, {
    this.timeout = const Duration(seconds: 6),
  });

  /// Best-effort cleanup when device scope is disposed.
  /// Not part of ScheduleRepository interface on purpose.
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
    _latest.clear();

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

  // -------------------- Public API --------------------

  @override
  Future<CalendarSnapshot> fetchAll({bool forceGet = false}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    if (!forceGet) {
      final cached = _last;
      if (cached != null) return cached;

      try {
        final snap = await firstWithTimeout<CalendarSnapshot>(
          watchSnapshot(),
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
      method: ScheduleJsonRpcCodec.methodGet,
      reqId: reqId,
      data: null,
      timeoutMessage: 'Timeout waiting for schedule get response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap == null) {
      throw StateError('Invalid schedule response');
    }
    _emitSnapshot(snap);
    return snap;
  }

  @override
  Future<void> saveAll(CalendarSnapshot snapshot, {String? reqId}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final prev = _last;
    final id = reqId ?? newReqId();

    String method;
    Map<String, dynamic> data;

    if (prev == null) {
      method = ScheduleJsonRpcCodec.methodSet;
      data = ScheduleJsonRpcCodec.encodeBody(snapshot);
    } else {
      final modeChanged = prev.mode.id != snapshot.mode.id;
      final pointsPatch = _pointsPatch(prev.lists, snapshot.lists);
      final rangeChanged = prev.range != snapshot.range;

      if (!modeChanged && pointsPatch.isEmpty && !rangeChanged) return;

      method = ScheduleJsonRpcCodec.methodPatch;
      data = ScheduleJsonRpcCodec.encodePatch(
        mode: modeChanged ? snapshot.mode : null,
        points: pointsPatch.isNotEmpty ? pointsPatch : null,
        range: rangeChanged ? snapshot.range : null,
      );
    }

    final resp = await _request(
      method: method,
      reqId: id,
      data: data,
      timeoutMessage: 'Timeout waiting for schedule save response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap != null) _emitSnapshot(snap);
  }

  @override
  Future<void> setMode(CalendarMode mode, {String? reqId}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final id = reqId ?? newReqId();
    final data = ScheduleJsonRpcCodec.encodePatch(mode: mode);
    final latest = _latest.start(_latestKey('mode'));

    final resp = await _request(
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
    if (snap != null) _emitSnapshot(snap);
  }

  @override
  Stream<CalendarSnapshot> watchSnapshot() {
    if (_disposed) return Stream<CalendarSnapshot>.empty();

    final existing = _ctrl;
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    late final StreamController<CalendarSnapshot> ctrl;
    ctrl = StreamController<CalendarSnapshot>.broadcast(
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
          if (c != null && !c.isClosed) await c.close();
        }
      },
    );

    _ctrl = ctrl;
    return ctrl.stream;
  }

  // -------------------- MQTT subscriptions --------------------

  void _ensureStateSubscription() {
    if (_stateSub != null) return;

    final topic = _topics.state(_deviceSn);
    _stateSub = _jrpc
        .notifications(
      topic,
      method: ScheduleJsonRpcCodec.methodState,
      schema: ScheduleJsonRpcCodec.schema,
    )
        .listen((notif) {
      final data = notif.data;
      if (data == null) return;

      final snap = ScheduleJsonRpcCodec.decodeBody(data);
      if (snap == null) return;

      _emitSnapshot(snap);
    });
  }

  // -------------------- JSON-RPC helpers --------------------

  void _emitSnapshot(CalendarSnapshot snap) {
    _last = snap;
    final ctrl = _ctrl;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(snap);
    }
  }

  JsonRpcMeta _meta() => JsonRpcMeta(
        schema: ScheduleJsonRpcCodec.schema,
        src: 'app',
        ts: DateTime.now().millisecondsSinceEpoch,
      );

  String _latestKey(String op) => op;

  Future<JsonRpcResponse> _request({
    required String method,
    required String reqId,
    required Map<String, dynamic>? data,
    required String timeoutMessage,
    Future<void>? cancel,
    Object? cancelError,
  }) async {
    return _jrpc.request(
      cmdTopic: _topics.cmd(_deviceSn),
      method: method,
      meta: _meta(),
      reqId: reqId,
      data: data,
      domain: ScheduleJsonRpcCodec.domain,
      timeout: timeout,
      timeoutMessage: timeoutMessage,
      cancel: cancel,
      cancelError: cancelError,
    );
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
    for (final m in CalendarMode.listModes) {
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
    return x.daysMask == y.daysMask && x.time.hour == y.time.hour && x.time.minute == y.time.minute && x.temp == y.temp;
  }
}
