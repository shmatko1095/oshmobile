// ScheduleRepository implementation backed by DeviceMqttRepo + ScheduleTopics (shadow pattern).
//
// Contract used here (align device firmware to it):
// - To fetch:
//   publishJson(getReq(deviceId), {"reqId": "..."}?) and wait for a retained/next JSON on reported(deviceId).
// - To save:
//   publishJson(desired(deviceId), {"reqId":"...", "mode":"...", "lists":{...}})
//   then wait for reported(deviceId) which either echoes this reqId OR simply republishes snapshot.
//
// We prefer matching reqId if firmware reflects it; otherwise we fall back to "first next reported".

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/features/schedule/data/schedule_topics.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryMqtt implements ScheduleRepository {
  final DeviceMqttRepo _mqtt;
  final ScheduleTopics _topics;
  final Duration timeout;

  ScheduleRepositoryMqtt(
    this._mqtt,
    this._topics, {
    this.timeout = const Duration(seconds: 6),
  });

  @override
  Future<CalendarSnapshot> fetchAll(String deviceId) async {
    final reportedTopic = _topics.reported(deviceId);
    final getTopic = _topics.getReq(deviceId);

    // 1) Subscribe to reported (will receive retained if exists).
    final stream = _mqtt.subscribeJson(reportedTopic);

    // 2) Ask device to publish current snapshot (race-safe).
    final reqId = _newReqId();
    unawaited(_mqtt.publishJson(getTopic, {'reqId': reqId}));

    // 3) Take the first reported we see (retained or fresh).
    final msg = await stream.first.timeout(timeout);
    return _decodeSnapshot(msg.payload);
  }

  @override
  Future<void> saveAll(String deviceId, CalendarSnapshot snapshot) async {
    final reportedTopic = _topics.reported(deviceId);
    final desiredTopic = _topics.desired(deviceId);

    final reqId = _newReqId();
    final payload = {
      'reqId': reqId,
      'mode': snapshot.mode.id,
      'lists': _encodeLists(snapshot.lists),
    };

    // 1) Subscribe to reported to catch echo/republish after desired is sent.
    final repStream = _mqtt.subscribeJson(reportedTopic);

    // 2) Publish desired bundle.
    await _mqtt.publishJson(desiredTopic, payload);

    // 3) Prefer correlation by reqId; otherwise accept first next reported.
    try {
      await repStream.map((e) => e.payload).firstWhere((p) => _matchesReqId(p, reqId)).timeout(timeout);
    } on TimeoutException {
      // Fallback: any next reported (republish without reqId).
      await repStream.first.timeout(timeout);
    }
  }

  // ---------------- Encoding / Decoding ----------------

  CalendarSnapshot _decodeSnapshot(dynamic raw) {
    final map = switch (raw) {
      String s => jsonDecode(s) as Map<String, dynamic>,
      Map<String, dynamic> m => m,
      _ => const <String, dynamic>{},
    };

    final modeStr = (map['mode'] as String?) ?? CalendarMode.off;
    final listsRaw = (map['lists'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    Map<CalendarMode, List<SchedulePoint>> lists = {
      CalendarMode.manual: _decodeList(listsRaw[CalendarMode.manual.id]),
      CalendarMode.antifreeze: _decodeList(listsRaw[CalendarMode.antifreeze.id]),
      CalendarMode.daily: _decodeList(listsRaw[CalendarMode.daily.id]),
      CalendarMode.weekly: _decodeList(listsRaw[CalendarMode.weekly.id]),
    };

    // Normalize for stability
    lists = lists.map((k, v) => MapEntry(k, _sortedDedup(v)));

    final mode = CalendarMode.all.firstWhere(
      (m) => m.id == modeStr,
      orElse: () => CalendarMode.off,
    );

    return CalendarSnapshot(mode: mode, lists: lists);
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
    for (final k in [
      CalendarMode.manual.id,
      CalendarMode.antifreeze.id,
      CalendarMode.daily.id,
      CalendarMode.weekly.id,
    ]) {
      out.putIfAbsent(k, () => <dynamic>[]);
    }
    return out;
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

    // support {"data":{"reqId":"..."}} just in case
    final data = (payload is Map) ? payload['data'] : null;
    if (data is Map && data['reqId']?.toString() == expected) return true;

    return false;
  }

  String _newReqId() => DateTime.now().microsecondsSinceEpoch.toString();

  int pMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
}
