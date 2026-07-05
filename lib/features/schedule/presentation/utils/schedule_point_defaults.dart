import 'package:flutter/material.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

String formatScheduleEditorTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatScheduleEditorTemperature(double value) =>
    value.toStringAsFixed(1);

SchedulePoint makeDefaultSchedulePoint(
  List<SchedulePoint> current,
  CalendarMode mode, [
  int stepMinutes = 15,
]) {
  final now = TimeOfDay.now();
  final time = nextFreeScheduleTime(current, now, stepMinutes);
  final last = current.isNotEmpty ? current.last : null;
  final daysMask = mode == CalendarMode.weekly
      ? (last?.daysMask ?? WeekdayMask.all)
      : WeekdayMask.all;
  final temp = last?.temp ?? 21.0;

  return SchedulePoint(
    time: time,
    daysMask: daysMask & WeekdayMask.all,
    temp: temp,
  );
}

TimeOfDay nextFreeScheduleTime(
  List<SchedulePoint> points,
  TimeOfDay start,
  int stepMinutes,
) {
  final used = <int>{};
  for (final point in points) {
    used.add(point.time.hour * 60 + point.time.minute);
  }

  final startMinutes = start.hour * 60 + start.minute;
  final candidate =
      ((startMinutes + stepMinutes - 1) ~/ stepMinutes) * stepMinutes;

  for (var i = 0; i < 1440 ~/ stepMinutes; i++) {
    final minuteOfDay = (candidate + i * stepMinutes) % 1440;
    if (!used.contains(minuteOfDay)) {
      return TimeOfDay(
        hour: minuteOfDay ~/ 60,
        minute: minuteOfDay % 60,
      );
    }
  }

  return start;
}
