part of 'schedule_jsonrpc_codec.dart';

CalendarMode? _parseMode(String id) {
  if (id.isEmpty) return null;
  for (final mode in CalendarMode.all) {
    if (mode.id == id) return mode;
  }
  return null;
}

SchedulePoint _pointWithSetpoint(
  Map<dynamic, dynamic> raw,
  ScheduleSetpoint setpoint,
) {
  final hour = (raw['hh'] as num?)?.toInt() ?? 0;
  final minute = (raw['mm'] as num?)?.toInt() ?? 0;
  final daysMask = (raw['mask'] as num?)?.toInt() ?? WeekdayMask.all;

  return SchedulePoint.withSetpoint(
    time: TimeOfDay(
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    ),
    daysMask: daysMask & WeekdayMask.all,
    setpoint: setpoint,
  );
}

Map<String, dynamic> _encodePointCoordinates(SchedulePoint point) {
  return <String, dynamic>{
    'hh': point.time.hour,
    'mm': point.time.minute,
    'mask': point.daysMask & WeekdayMask.all,
  };
}

double _roundTemperature(double value) {
  return double.parse(value.toStringAsFixed(1));
}

List<SchedulePoint> _sortedDedup(List<SchedulePoint> points) {
  final byTimeAndMask = <String, SchedulePoint>{};
  for (final point in points) {
    final key = '${point.daysMask}:${point.time.hour}:${point.time.minute}';
    byTimeAndMask[key] = point;
  }

  return byTimeAndMask.values.toList()
    ..sort((a, b) {
      final aMinute = a.time.hour * 60 + a.time.minute;
      final bMinute = b.time.hour * 60 + b.time.minute;
      if (aMinute != bMinute) return aMinute.compareTo(bMinute);
      return a.daysMask.compareTo(b.daysMask);
    });
}

ScheduleRange? _decodeRange(dynamic raw) {
  if (raw == null) return const ScheduleRange.defaults();
  if (raw is! Map) return null;
  final min = (raw['min'] as num?)?.toDouble();
  final max = (raw['max'] as num?)?.toDouble();
  if (min == null || max == null) return null;
  return ScheduleRange(min: min, max: max).normalized();
}

Map<String, dynamic> _encodeRange(ScheduleRange range) {
  final normalized = range.normalized();
  return <String, dynamic>{
    'min': _roundTemperature(normalized.min),
    'max': _roundTemperature(normalized.max),
  };
}
