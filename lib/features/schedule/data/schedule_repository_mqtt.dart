// MQTT-backed ScheduleRepository using shadow pattern.
// Partial publish:
// - setMode() publishes only {reqId, mode}.
// - saveAll() publishes only changed lists (and mode if changed).
// Receiving still merges partials into _last[].

import 'dart:async';
import 'dart:convert';

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

    _subs.clear();
    _ctrls.clear();
    _refs.clear();
    _last.clear();

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
  }

  // Stream waiting helpers live in core/utils/stream_waiters.dart.
  ScheduleRepositoryMqtt(
    this._mqtt,
    this._topics, {
    this.timeout = const Duration(seconds: 6),
  });

  @override
  Future<CalendarSnapshot> fetchAll(String deviceId) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final reportedTopic = _topics.reported(deviceId);
    final getTopic = _topics.getReq(deviceId);

    final stream = _mqtt.subscribeJson(reportedTopic);

    final reqId = newReqId();
    unawaited(_mqtt.publishJson(getTopic, {'reqId': reqId}));

    final msg = await firstWithTimeout(
      stream,
      timeout,
      timeoutMessage: 'Timeout waiting for first schedule reported',
    );
    final map = _decodeMap(msg.payload);
    final snap = _mergePartial(deviceId, map);
    _last[deviceId] = snap;
    return snap;
  }

  @override
  Future<void> saveAll(String deviceId, CalendarSnapshot snapshot, {String? reqId}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final reportedTopic = _topics.reported(deviceId);
    final desiredTopic = _topics.desired(deviceId);

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

    // Nothing to send? still publish reqId to get ack flow (rare case)
    final repStream = _mqtt.subscribeJson(reportedTopic);
    await _mqtt.publishJson(desiredTopic, payload);

    // Prefer correlation by reqId; otherwise accept first next reported.
    try {
      await firstWhereWithTimeout<dynamic>(
        repStream.map((e) => e.payload),
        (p) => _matchesReqId(p, id),
        timeout,
        timeoutMessage: 'Timeout waiting for schedule ACK',
      );
    } on TimeoutException {
      await firstWithTimeout(
        repStream,
        timeout,
        timeoutMessage: 'Timeout waiting for schedule reported after publish',
      );
    }
  }

  @override
  Future<void> setMode(String deviceId, CalendarMode mode, {String? reqId}) async {
    if (_disposed) throw StateError('ScheduleRepositoryMqtt is disposed');

    final reportedTopic = _topics.reported(deviceId);
    final desiredTopic = _topics.desired(deviceId);

    final id = reqId ?? newReqId();
    final payload = {
      'reqId': id,
      'mode': mode.id, // only mode, no lists
    };

    final repStream = _mqtt.subscribeJson(reportedTopic);
    await _mqtt.publishJson(desiredTopic, payload);

    try {
      await firstWhereWithTimeout<dynamic>(
        repStream.map((e) => e.payload),
        (p) => _matchesReqId(p, id),
        timeout,
        timeoutMessage: 'Timeout waiting for schedule ACK',
      );
    } on TimeoutException {
      await firstWithTimeout(
        repStream,
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

        final reportedTopic = _topics.reported(deviceId);
        final getTopic = _topics.getReq(deviceId);

        _subs[deviceId] = _mqtt.subscribeJson(reportedTopic).listen((msg) {
          final map = _decodeMap(msg.payload);
          final applied = _extractAppliedReqId(map);
          final snap = _mergePartial(deviceId, map);

          _last[deviceId] = snap;
          if (!ctrl.isClosed) ctrl.add(MapEntry(applied, snap));
        });

        // Ask for retained snapshot.
        unawaited(_mqtt.publishJson(getTopic, {'reqId': newReqId()}));
      },
      onCancel: () async {
        _refs[deviceId] = (_refs[deviceId] ?? 1) - 1;
        if (_refs[deviceId]! <= 0) {
          _refs.remove(deviceId);
          await _subs.remove(deviceId)?.cancel();
          final c = _ctrls.remove(deviceId);
          if (c != null && !c.isClosed) await c.close();
        }
      },
    );

    _ctrls[deviceId] = ctrl;
    return ctrl.stream;
  }

  // ---------------- Encoding / Decoding ----------------

  Map<String, dynamic> _decodeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String) return (jsonDecode(raw) as Map).cast<String, dynamic>();
    return const <String, dynamic>{};
  }

  String? _extractAppliedReqId(Map<String, dynamic> map) {
    final meta = map['meta'];
    if (meta is Map) {
      final mm = meta.cast<String, dynamic>();
      final v = mm['lastAppliedReqId'];
      if (v != null) return v.toString();
    }
    // Fallback: some FW echoes reqId at the top level.
    final v = map['reqId'];
    return v?.toString();
  }

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

  bool _matchesReqId(dynamic payload, String expected) {
    if (payload == null) return false;
    if (payload is String) return payload == expected;
    if (payload is Map && payload['reqId']?.toString() == expected) return true;

    final meta = (payload is Map) ? payload['meta'] : null;
    if (meta is Map && meta['lastAppliedReqId']?.toString() == expected) return true;

    final data = (payload is Map) ? payload['data'] : null;
    if (data is Map && data['reqId']?.toString() == expected) return true;

    return false;
  }

  int pMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
}
