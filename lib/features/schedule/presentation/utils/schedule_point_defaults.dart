import 'package:flutter/material.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

String formatScheduleEditorTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatScheduleEditorTemperature(double value) =>
    value.toStringAsFixed(1);

String formatScheduleEditorSetpoint(ScheduleSetpoint value) {
  if (value.isOn) return 'ON';
  if (value.isOff) return 'OFF';
  return '${formatScheduleEditorTemperature(value.temperature!)}°C';
}

ScheduleSetpoint stepScheduleSetpoint(
  ScheduleSetpoint current,
  double delta, {
  required Set<ScheduleSetpointKind> supportedSetpointKinds,
  double min = 10.0,
  double max = 40.0,
  double step = 0.5,
}) {
  if (delta == 0) return current;
  if (current.isOff) {
    return delta > 0
        ? ScheduleSetpoint.temperature(min)
        : const ScheduleSetpoint.off();
  }
  if (current.isOn) {
    return delta < 0
        ? ScheduleSetpoint.temperature(max)
        : const ScheduleSetpoint.on();
  }
  final value = current.temperature!;
  if (delta < 0 && value <= min) {
    return supportedSetpointKinds.contains(ScheduleSetpointKind.off)
        ? const ScheduleSetpoint.off()
        : ScheduleSetpoint.temperature(min);
  }
  if (delta > 0 && value >= max) {
    return supportedSetpointKinds.contains(ScheduleSetpointKind.on)
        ? const ScheduleSetpoint.on()
        : ScheduleSetpoint.temperature(max);
  }
  final next = (value + (delta.sign * step)).clamp(min, max);
  return ScheduleSetpoint.temperature(double.parse(next.toStringAsFixed(1)));
}

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
  final setpoint = last?.setpoint ?? const ScheduleSetpoint.temperature(21.0);

  return SchedulePoint.withSetpoint(
    time: time,
    daysMask: daysMask & WeekdayMask.all,
    setpoint: setpoint,
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
