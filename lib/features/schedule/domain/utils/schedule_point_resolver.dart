import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

SchedulePoint? resolveCurrentPoint(
  CalendarSnapshot snapshot, {
  DateTime? now,
}) {
  now ??= DateTime.now();
  final points = snapshot.pointsFor(snapshot.mode);
  if (points.isEmpty) return null;

  if (snapshot.mode == CalendarMode.weekly) {
    return _currentForWeekly(points, now);
  }
  return _currentFor(points, now);
}

SchedulePoint? resolveNextPoint(
  CalendarSnapshot snapshot, {
  DateTime? now,
}) {
  if (snapshot.mode != CalendarMode.daily && snapshot.mode != CalendarMode.weekly) {
    return null;
  }

  now ??= DateTime.now();
  final points = snapshot.pointsFor(snapshot.mode);
  if (points.isEmpty) return null;

  if (snapshot.mode == CalendarMode.weekly) {
    return _nextForWeekly(points, now);
  }
  return _nextFor(points, now);
}

SchedulePoint? _currentForWeekly(List<SchedulePoint> points, DateTime now) {
  final nowMin = now.hour * 60 + now.minute;
  final nowWeekMin = (now.weekday - 1) * 1440 + nowMin;

  SchedulePoint? best;
  var bestWeekMin = -1;

  SchedulePoint? wrap;
  var wrapWeekMin = -1;

  for (final point in points) {
    final timeMinutes = point.time.hour * 60 + point.time.minute;

    for (var weekday = 1; weekday <= 7; weekday++) {
      if (!WeekdayMask.includes(point.daysMask, weekday)) continue;

      final weekMinutes = (weekday - 1) * 1440 + timeMinutes;
      if (weekMinutes <= nowWeekMin && weekMinutes > bestWeekMin) {
        bestWeekMin = weekMinutes;
        best = point;
      }

      if (weekMinutes > wrapWeekMin) {
        wrapWeekMin = weekMinutes;
        wrap = point;
      }
    }
  }

  return best ?? wrap;
}

SchedulePoint? _nextForWeekly(List<SchedulePoint> points, DateTime now) {
  final nowMin = now.hour * 60 + now.minute;
  final nowWeekMin = (now.weekday - 1) * 1440 + nowMin;

  SchedulePoint? best;
  var bestWeekMin = 9999999;

  SchedulePoint? wrap;
  var wrapWeekMin = 9999999;

  for (final point in points) {
    final timeMinutes = point.time.hour * 60 + point.time.minute;

    for (var weekday = 1; weekday <= 7; weekday++) {
      if (!WeekdayMask.includes(point.daysMask, weekday)) continue;

      final weekMinutes = (weekday - 1) * 1440 + timeMinutes;
      if (weekMinutes > nowWeekMin && weekMinutes < bestWeekMin) {
        bestWeekMin = weekMinutes;
        best = point;
      }

      if (weekMinutes < wrapWeekMin) {
        wrapWeekMin = weekMinutes;
        wrap = point;
      }
    }
  }

  return best ?? wrap;
}

SchedulePoint? _currentFor(List<SchedulePoint> points, DateTime now) {
  final nowMinutes = now.hour * 60 + now.minute;

  SchedulePoint? best;
  var bestMinutes = -1;

  for (final point in points) {
    final pointMinutes = point.time.hour * 60 + point.time.minute;
    if (pointMinutes <= nowMinutes && pointMinutes > bestMinutes) {
      bestMinutes = pointMinutes;
      best = point;
    }
  }

  return best ?? points.last;
}

SchedulePoint? _nextFor(List<SchedulePoint> points, DateTime now) {
  final nowMinutes = now.hour * 60 + now.minute;

  SchedulePoint? best;
  var bestMinutes = 999999;

  for (final point in points) {
    final pointMinutes = point.time.hour * 60 + point.time.minute;
    if (pointMinutes > nowMinutes && pointMinutes < bestMinutes) {
      bestMinutes = pointMinutes;
      best = point;
    }
  }

  return best ?? points.first;
}
