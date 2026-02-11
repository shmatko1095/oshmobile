import 'package:flutter/material.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

/// Codec for schedule@1 JSON-RPC payloads.
///
/// Body shape:
/// {
///   "mode": "off" | "on" | "daily" | "weekly" | "range",
///   "points": {
///     "off":  [ {"temp": 5.0,  "hh": 0, "mm": 0, "mask": 127}, ... ],
///     "on":   [ {"temp": 21.0, "hh": 6, "mm": 0, "mask": 127}, ... ],
///     "daily": [ ... ],
///     "weekly": [ ... ],
///     "range": { "min": 15.0, "max": 18.5 }
///   }
/// }
class ScheduleJsonRpcCodec {
  static const String schema = 'schedule@1';
  static const String domain = 'schedule';

  static String methodOf(String op) => '$domain.$op';

  static String get methodState => methodOf('state');

  static String get methodGet => methodOf('get');

  static String get methodSet => methodOf('set');

  static String get methodPatch => methodOf('patch');

  static CalendarSnapshot? decodeBody(Map<String, dynamic> data) {
    final modeStr = data['mode'];
    if (modeStr is! String) return null;

    final pointsRaw = data['points'];
    if (pointsRaw is! Map) return null;

    final mode = _parseMode(modeStr) ?? CalendarMode.off;
    final lists = <CalendarMode, List<SchedulePoint>>{};

    for (final m in CalendarMode.listModes) {
      final rawList = pointsRaw[m.id];
      final decodedRaw = _decodePoints(rawList);
      lists[m] = _sortedDedup(decodedRaw);
    }

    final range = _decodeRange(pointsRaw['range']);
    if (range == null && pointsRaw.containsKey('range')) return null;

    return CalendarSnapshot(mode: mode, range: range, lists: lists);
  }

  static Map<String, dynamic> encodeBody(CalendarSnapshot snapshot) {
    return <String, dynamic>{
      'mode': snapshot.mode.id,
      'points': _encodePoints(snapshot.lists, range: snapshot.range, includeAllListModes: true),
    };
  }

  static Map<String, dynamic> encodePatch({
    CalendarMode? mode,
    Map<CalendarMode, List<SchedulePoint>>? points,
    ScheduleRange? range,
  }) {
    final out = <String, dynamic>{};
    if (mode != null) out['mode'] = mode.id;
    if ((points != null && points.isNotEmpty) || range != null) {
      out['points'] = _encodePoints(
        points ?? const {},
        range: range,
        includeAllListModes: false,
      );
    }
    return out;
  }

  static CalendarMode? _parseMode(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final m in CalendarMode.all) {
      if (m.id == id) return m;
    }
    return null;
  }

  static List<SchedulePoint> _decodePoints(dynamic raw) {
    if (raw is! List) return const <SchedulePoint>[];

    final out = <SchedulePoint>[];
    for (final item in raw) {
      if (item is! Map) continue;

      final temp = (item['temp'] as num?)?.toDouble();

      final hh = (item['hh'] as num?)?.toInt() ?? 0;
      final mm = (item['mm'] as num?)?.toInt() ?? 0;
      final mask = (item['mask'] as num?)?.toInt() ?? WeekdayMask.all;

      if (temp == null) continue;

      out.add(
        SchedulePoint(
          time: TimeOfDay(hour: hh.clamp(0, 23), minute: mm.clamp(0, 59)),
          daysMask: mask & WeekdayMask.all,
          temp: double.parse(temp.toStringAsFixed(1)),
        ),
      );
    }
    return out;
  }

  static Map<String, dynamic> _encodePoints(
    Map<CalendarMode, List<SchedulePoint>> lists, {
    ScheduleRange? range,
    required bool includeAllListModes,
  }) {
    final out = <String, dynamic>{};
    if (includeAllListModes) {
      for (final m in CalendarMode.listModes) {
        final pts = lists[m] ?? const <SchedulePoint>[];
        out[m.id] = _encodePointsList(pts);
      }
    } else {
      for (final entry in lists.entries) {
        out[entry.key.id] = _encodePointsList(entry.value);
      }
    }
    if (range != null) {
      out['range'] = _encodeRange(range);
    }
    return out;
  }

  static List<Map<String, dynamic>> _encodePointsList(List<SchedulePoint> points) {
    return points.map(_encodePoint).toList(growable: false);
  }

  static Map<String, dynamic> _encodePoint(SchedulePoint p) {
    return <String, dynamic>{
      'temp': double.parse(p.temp.toStringAsFixed(1)),
      'hh': p.time.hour,
      'mm': p.time.minute,
      'mask': p.daysMask & WeekdayMask.all,
    };
  }

  static List<SchedulePoint> _sortedDedup(List<SchedulePoint> pts) {
    final map = <String, SchedulePoint>{};
    for (final p in pts) {
      final key = '${p.daysMask}:${p.time.hour}:${p.time.minute}';
      map[key] = p; // last wins
    }

    final out = map.values.toList()
      ..sort((a, b) {
        final ai = a.time.hour * 60 + a.time.minute;
        final bi = b.time.hour * 60 + b.time.minute;
        if (ai != bi) return ai.compareTo(bi);
        return a.daysMask.compareTo(b.daysMask);
      });
    return out;
  }

  static ScheduleRange? _decodeRange(dynamic raw) {
    if (raw == null) return const ScheduleRange.defaults();
    if (raw is! Map) return null;
    final minV = (raw['min'] as num?)?.toDouble();
    final maxV = (raw['max'] as num?)?.toDouble();
    if (minV == null || maxV == null) return null;
    return ScheduleRange(min: minV, max: maxV).normalized();
  }

  static Map<String, dynamic> _encodeRange(ScheduleRange range) {
    final normalized = range.normalized();
    return <String, dynamic>{
      'min': double.parse(normalized.min.toStringAsFixed(1)),
      'max': double.parse(normalized.max.toStringAsFixed(1)),
    };
  }
}
