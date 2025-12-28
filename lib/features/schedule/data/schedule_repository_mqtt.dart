// MQTT-backed ScheduleRepository using shadow pattern.
// Partial publish:
// - setMode() publishes only {reqId, mode}.
// - saveAll() publishes only changed lists (and mode if changed).
// Receiving still merges partials into _last[].

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/stream_waiters.dart';
import 'package:oshmobile/features/schedule/data/schedule_topics.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryMqtt implements ScheduleRepository {
  final DeviceMqttRepo _mqtt;
  final ScheduleTopics _topics;
  final Duration timeout;

  final Map<String, StreamController<MapEntry<String?, CalendarSnapshot>>> _ctrls = {};
  final Map<String, StreamSubscription> _subs = {};
  final Map<String, int> _refs = {};
  final Map<String, CalendarSnapshot> _last = {};

  // Reported raw events fan-out (used for ACK waiting without re-subscribing).
  final Map<String, StreamController<MapEntry<int, dynamic>>> _rawCtrls = {};
  final Map<String, int> _seq = {};

  bool _disposed = false;

  /// Best-effort cleanup when session scope is disposed.
  /// Not part of ScheduleRepository interface on purpose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final subs = _subs.values.toList(growable: false);
    final ctrls = _ctrls.values.toList(growable: false);
    final rawCtrls = _rawCtrls.values.toList(growable: false);

    _subs.clear();
    _ctrls.clear();
    _rawCtrls.clear();

    _refs.clear();
    _last.clear();
    _seq.clear();

    for (final s in subs) {
      try {
        await s.cancel();
      } catch (_) {}
    }
    for (final c in ctrls) {
      try {
        if (!c.isClosed) await c.close();
      } catch (_) {}
    }
    for (final c in rawCtrls) {
      try {
        if (!c.isClosed) await c.close();
      } catch (_) {}
    }
  }

  // Stream waiting helpers live in core/utils/stream_waiters.dart.
  ScheduleRepositoryMqtt(
    this._mqtt,
    this._topics, {
    this.timeout = const Duration(seconds: 6),
  });

  @override
  @override
  Future<CalendarSnapshot> fetchAll(String deviceId) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final getTopic = _topics.getReq(deviceId);

    _ensureReportedSubscription(deviceId);
    final events = _reportedEvents(deviceId);

    // "Cursor" to ensure we only accept events after the request start.
    final startSeq = _seq[deviceId] ?? 0;

    final waitNext = firstWhereWithTimeout<MapEntry<int, dynamic>>(
      events,
      (e) => e.key > startSeq,
      timeout,
      timeoutMessage: 'Timeout waiting for first schedule reported',
    );

    // Request snapshot (device is expected to respond on reported topic).
    unawaited(_mqtt.publishJson(getTopic, {'reqId': newReqId()}));

    final ev = await waitNext;

    final map = decodeMqttMap(ev.value);
    final snap = _mergePartial(deviceId, map);
    _last[deviceId] = snap;
    return snap;
  }

  @override
  @override
  Future<void> saveAll(String deviceId, CalendarSnapshot snapshot, {String? reqId}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final desiredTopic = _topics.desired(deviceId);

    _ensureReportedSubscription(deviceId);
    final events = _reportedEvents(deviceId);

    final id = reqId ?? newReqId();

    // Decide: full vs partial lists
    final hasPrev = _last.containsKey(deviceId);
    final prev = _last[deviceId] ?? CalendarSnapshot.empty();

    final modeChanged = prev.mode.id != snapshot.mode.id;
    final listsPatch = hasPrev ? _encodeListsPatch(prev.lists, snapshot.lists) : _encodeLists(snapshot.lists);

    // Build payload only with changed parts
    final payload = <String, dynamic>{'reqId': id};
    if (modeChanged) payload['mode'] = snapshot.mode.id;
    if (listsPatch.isNotEmpty) payload['lists'] = listsPatch;

    // Cursor to avoid consuming older reported messages.
    final startSeq = _seq[deviceId] ?? 0;

    // Attach waiter before publish to avoid race (fast ACK).
    final ackWait = firstWhereWithTimeout<MapEntry<int, dynamic>>(
      events,
      (e) => e.key > startSeq && matchesReqId(e.value, id),
      timeout,
      timeoutMessage: 'Timeout waiting for schedule ACK',
    );

    await _mqtt.publishJson(desiredTopic, payload);

    // Prefer correlation by reqId; otherwise accept "next reported" (legacy behavior).
    try {
      await ackWait;
    } on TimeoutException {
      await firstWhereWithTimeout<MapEntry<int, dynamic>>(
        events,
        (e) => e.key > startSeq,
        timeout,
        timeoutMessage: 'Timeout waiting for schedule reported after publish',
      );
    }
  }

  @override
  @override
  Future<void> setMode(String deviceId, CalendarMode mode, {String? reqId}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final desiredTopic = _topics.desired(deviceId);

    _ensureReportedSubscription(deviceId);
    final events = _reportedEvents(deviceId);

    final id = reqId ?? newReqId();
    final payload = {
      'reqId': id,
      'mode': mode.id, // only mode, no lists
    };

    final startSeq = _seq[deviceId] ?? 0;

    final ackWait = firstWhereWithTimeout<MapEntry<int, dynamic>>(
      events,
      (e) => e.key > startSeq && matchesReqId(e.value, id),
      timeout,
      timeoutMessage: 'Timeout waiting for schedule ACK',
    );

    await _mqtt.publishJson(desiredTopic, payload);

    try {
      await ackWait;
    } on TimeoutException {
      await firstWhereWithTimeout<MapEntry<int, dynamic>>(
        events,
        (e) => e.key > startSeq,
        timeout,
        timeoutMessage: 'Timeout waiting for schedule reported after setMode',
      );
    }
  }

  @override
  Stream<MapEntry<String?, CalendarSnapshot>> watchSnapshot(String deviceId) {
    if (_disposed) return Stream<MapEntry<String?, CalendarSnapshot>>.empty();

    final existing = _ctrls[deviceId];
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    late final StreamController<MapEntry<String?, CalendarSnapshot>> ctrl;
    ctrl = StreamController<MapEntry<String?, CalendarSnapshot>>.broadcast(
      onListen: () async {
        _refs[deviceId] = (_refs[deviceId] ?? 0) + 1;
        if (_refs[deviceId]! > 1) return;

        final getTopic = _topics.getReq(deviceId);
        _ensureReportedSubscription(deviceId);
        unawaited(_mqtt.publishJson(getTopic, {'reqId': newReqId()}));
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

  // ---------------- Encoding / Decoding ----------------

  /// Merge a partial reported map into last known snapshot for [deviceId].
  /// - If 'mode' is absent => keep previous mode.
  /// - If 'lists' present => update only listed keys; empty arrays overwrite to [].
  CalendarSnapshot _mergePartial(String deviceId, Map<String, dynamic> map) {
    final prev = _last[deviceId] ?? CalendarSnapshot.empty();

    CalendarMode nextMode = prev.mode;
    if (map.containsKey('mode')) {
      final modeStr = map['mode'] as String?;
      final found = CalendarMode.all.firstWhere(
        (m) => m.id == modeStr,
        orElse: () => prev.mode,
      );
      nextMode = found;
    }

    final mergedLists = <CalendarMode, List<SchedulePoint>>{
      CalendarMode.off: List<SchedulePoint>.from(prev.lists[CalendarMode.off] ?? const <SchedulePoint>[]),
      CalendarMode.on: List<SchedulePoint>.from(prev.lists[CalendarMode.on] ?? const <SchedulePoint>[]),
      CalendarMode.antifreeze: List<SchedulePoint>.from(prev.lists[CalendarMode.antifreeze] ?? const <SchedulePoint>[]),
      CalendarMode.daily: List<SchedulePoint>.from(prev.lists[CalendarMode.daily] ?? const <SchedulePoint>[]),
      CalendarMode.weekly: List<SchedulePoint>.from(prev.lists[CalendarMode.weekly] ?? const <SchedulePoint>[]),
    };

    final listsRaw = (map['lists'] as Map?)?.cast<String, dynamic>();
    if (listsRaw != null) {
      void apply(CalendarMode m) {
        if (listsRaw.containsKey(m.id)) {
          mergedLists[m] = _sortedDedup(_decodeList(listsRaw[m.id]));
        }
      }

      apply(CalendarMode.off);
      apply(CalendarMode.on);
      apply(CalendarMode.antifreeze);
      apply(CalendarMode.daily);
      apply(CalendarMode.weekly);
    }

    return CalendarSnapshot(mode: nextMode, lists: mergedLists);
  }

  List<SchedulePoint> _decodeList(dynamic v) {
    final list = (v as List?) ?? const [];
    return list.whereType<Map>().map((m) {
      final hh = (m['hh'] as num?)?.toInt() ?? 0;
      final mm = (m['mm'] as num?)?.toInt() ?? 0;
      final d = (m['d'] as num?)?.toInt() ?? WeekdayMask.all;
      final a = (m['min'] as num?)?.toDouble() ?? 21.0;
      final b = (m['max'] as num?)?.toDouble() ?? a;
      final lo = a <= b ? a : b, hi = b >= a ? b : a;
      return SchedulePoint(
        time: TimeOfDay(hour: hh.clamp(0, 23), minute: mm.clamp(0, 59)),
        daysMask: d & WeekdayMask.all,
        min: double.parse(lo.toStringAsFixed(1)),
        max: double.parse(hi.toStringAsFixed(1)),
      );
    }).toList();
  }

  Map<String, dynamic> _encodeLists(Map<CalendarMode, List<SchedulePoint>> lists) {
    final out = <String, dynamic>{};
    for (final e in lists.entries) {
      out[e.key.id] = e.value.map(_encodePoint).toList();
    }
    return out;
  }

  /// Build partial 'lists' object: only keys whose content differs from prev.
  Map<String, dynamic> _encodeListsPatch(
    Map<CalendarMode, List<SchedulePoint>> prev,
    Map<CalendarMode, List<SchedulePoint>> next,
  ) {
    final out = <String, dynamic>{};
    bool diff(CalendarMode m) => !_listsEqual(prev[m] ?? const [], next[m] ?? const []);
    void put(CalendarMode m) {
      if (diff(m)) {
        out[m.id] = (next[m] ?? const <SchedulePoint>[]).map(_encodePoint).toList();
      }
    }

    put(CalendarMode.off);
    put(CalendarMode.on);
    put(CalendarMode.antifreeze);
    put(CalendarMode.daily);
    put(CalendarMode.weekly);

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

  Map<String, dynamic> _encodePoint(SchedulePoint p) => {
        'hh': p.time.hour,
        'mm': p.time.minute,
        'd': p.daysMask,
        'min': p.min,
        'max': p.max,
      };

  List<SchedulePoint> _sortedDedup(List<SchedulePoint> pts) {
    final map = <String, SchedulePoint>{};
    for (final p in pts) {
      final key = '${p.daysMask}:${p.time.hour}:${p.time.minute}';
      map[key] = p; // last wins
    }
    final out = map.values.toList()
      ..sort((a, b) {
        final ai = pMinutes(a.time);
        final bi = pMinutes(b.time);
        if (ai != bi) return ai.compareTo(bi);
        return a.daysMask.compareTo(b.daysMask);
      });
    return out;
  }

  int pMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Ensures there is exactly one MQTT subscription to the reported topic per device.
  /// The subscription does not depend on UI watchers and stays alive until dispose().
  void _ensureReportedSubscription(String deviceId) {
    if (_subs.containsKey(deviceId)) return;

    final reportedTopic = _topics.reported(deviceId);

    _subs[deviceId] = _mqtt.subscribeJson(reportedTopic).listen((msg) {
      final nextSeq = (_seq[deviceId] ?? 0) + 1;
      _seq[deviceId] = nextSeq;

      // 1) Fan-out raw payload for ACK waiters.
      final rawCtrl = _rawCtrls[deviceId];
      if (rawCtrl != null && !rawCtrl.isClosed) {
        rawCtrl.add(MapEntry(nextSeq, msg.payload));
      }

      // 2) Decode + merge to snapshot stream (if someone watches snapshots).
      final map = decodeMqttMap(msg.payload);
      final applied = extractReqIdFromMap(map);
      final snap = _mergePartial(deviceId, map);

      _last[deviceId] = snap;

      final snapCtrl = _ctrls[deviceId];
      if (snapCtrl != null && !snapCtrl.isClosed) {
        snapCtrl.add(MapEntry(applied, snap));
      }
    });
  }

  /// Returns a broadcast stream of raw reported payloads with monotonic sequence numbers.
  /// Sequence numbers allow "wait for next" semantics without re-subscribing.
  Stream<MapEntry<int, dynamic>> _reportedEvents(String deviceId) {
    final existing = _rawCtrls[deviceId];
    if (existing != null && !existing.isClosed) return existing.stream;

    final ctrl = StreamController<MapEntry<int, dynamic>>.broadcast(
      onListen: () {
        _ensureReportedSubscription(deviceId);
      },
    );
    _rawCtrls[deviceId] = ctrl;
    return ctrl.stream;
  }
}
