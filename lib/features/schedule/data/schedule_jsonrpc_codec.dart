import 'package:flutter/material.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

/// Codec for schedule@1 JSON-RPC payloads.
///
/// Body shape:
/// {
///   "mode": "off" | "on" | "daily" | "weekly" | "antifreeze",
///   "points": {
///     "off":  [ {"temp": 5.0,  "hh": 0, "mm": 0, "mask": 127} | {"temp_min":4.5,"temp_max":5.0,...}, ... ],
///     "on":   [ {"temp": 21.0, "hh": 6, "mm": 0, "mask": 127} | {"temp_min":20.5,"temp_max":21.0,...}, ... ],
///     "daily": [ ... ],
///     "weekly": [ ... ],
///     "antifreeze": [ ... ]
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

    for (final m in CalendarMode.all) {
      final rawList = pointsRaw[m.id];
      final decodedRaw = _decodePoints(rawList);
      if (m == CalendarMode.antifreeze) {
        final normalized = _normalizeAntifreeze(decodedRaw);
        lists[m] = _sortedDedup(normalized);
      } else {
        lists[m] = _sortedDedup(decodedRaw);
      }
    }

    return CalendarSnapshot(mode: mode, lists: lists);
  }

  static Map<String, dynamic> encodeBody(CalendarSnapshot snapshot) {
    return <String, dynamic>{
      'mode': snapshot.mode.id,
      'points': _encodePoints(snapshot.lists),
    };
  }

  static Map<String, dynamic> encodePatch({
    CalendarMode? mode,
    Map<CalendarMode, List<SchedulePoint>>? points,
  }) {
    final out = <String, dynamic>{};
    if (mode != null) out['mode'] = mode.id;
    if (points != null && points.isNotEmpty) {
      out['points'] = _encodePoints(points);
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
      final tempMin = (item['temp_min'] as num?)?.toDouble();
      final tempMax = (item['temp_max'] as num?)?.toDouble();

      final hh = (item['hh'] as num?)?.toInt() ?? 0;
      final mm = (item['mm'] as num?)?.toInt() ?? 0;
      final mask = (item['mask'] as num?)?.toInt() ?? WeekdayMask.all;

      double? lo;
      double? hi;

      if (tempMin != null || tempMax != null) {
        lo = tempMin ?? tempMax;
        hi = tempMax ?? tempMin;
      } else if (temp != null) {
        lo = temp;
        hi = temp;
      }

      if (lo == null || hi == null) continue;

      out.add(
        SchedulePoint(
          time: TimeOfDay(hour: hh.clamp(0, 23), minute: mm.clamp(0, 59)),
          daysMask: mask & WeekdayMask.all,
          min: double.parse(lo.toStringAsFixed(1)),
          max: double.parse(hi.toStringAsFixed(1)),
        ),
      );
    }
    return out;
  }

  static Map<String, dynamic> _encodePoints(Map<CalendarMode, List<SchedulePoint>> lists) {
    final out = <String, dynamic>{};
    for (final entry in lists.entries) {
      out[entry.key.id] = _encodePointsList(entry.key, entry.value);
    }
    return out;
  }

  static List<Map<String, dynamic>> _encodePointsList(CalendarMode mode, List<SchedulePoint> points) {
    if (mode == CalendarMode.antifreeze && points.length == 1) {
      final p = points.first;
      if (p.min != p.max) {
        final lo = (p.min <= p.max) ? p.min : p.max;
        final hi = (p.max >= p.min) ? p.max : p.min;
        return [
          _encodePointWithTemp(p, lo),
          _encodePointWithTemp(p, hi),
        ];
      }
    }

    return points.map(_encodePoint).toList(growable: false);
  }

  static Map<String, dynamic> _encodePoint(SchedulePoint p) {
    // schedule@1 uses a single `temp` value per point.
    final lo = (p.min <= p.max) ? p.min : p.max;
    final hi = (p.max >= p.min) ? p.max : p.min;
    if (lo == hi) {
      return _encodePointWithTemp(p, lo);
    }
    return <String, dynamic>{
      'temp_min': double.parse(lo.toStringAsFixed(1)),
      'temp_max': double.parse(hi.toStringAsFixed(1)),
      'hh': p.time.hour,
      'mm': p.time.minute,
      'mask': p.daysMask & WeekdayMask.all,
    };
  }

  static Map<String, dynamic> _encodePointWithTemp(SchedulePoint p, double temp) {
    return <String, dynamic>{
      'temp': double.parse(temp.toStringAsFixed(1)),
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

  static List<SchedulePoint> _normalizeAntifreeze(List<SchedulePoint> pts) {
    if (pts.length != 2) return pts;

    final a = pts[0];
    final b = pts[1];
    final sameTime = a.time.hour == b.time.hour && a.time.minute == b.time.minute && a.daysMask == b.daysMask;
    if (!sameTime) return pts;

    if (a.isRange || b.isRange) return pts;

    final lo = (a.min <= b.min) ? a.min : b.min;
    final hi = (a.max >= b.max) ? a.max : b.max;
    return [
      SchedulePoint(
        time: a.time,
        daysMask: a.daysMask,
        min: double.parse(lo.toStringAsFixed(1)),
        max: double.parse(hi.toStringAsFixed(1)),
      ),
    ];
  }
}
