import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

class CalendarSnapshot {
  final CalendarMode mode;
  final Map<CalendarMode, List<SchedulePoint>> lists;

  const CalendarSnapshot({
    required this.mode,
    required this.lists,
  });

  List<SchedulePoint> pointsFor(CalendarMode m) => List.unmodifiable(lists[m] ?? const <SchedulePoint>[]);

  CalendarSnapshot copyWith({
    CalendarMode? mode,
    Map<CalendarMode, List<SchedulePoint>>? lists,
  }) =>
      CalendarSnapshot(
        mode: mode ?? this.mode,
        lists: lists ?? this.lists,
      );

  static CalendarSnapshot empty([CalendarMode mode = CalendarMode.weekly]) => CalendarSnapshot(
        mode: mode,
        lists: Map<CalendarMode, List<SchedulePoint>>.unmodifiable({
          CalendarMode.manual: const <SchedulePoint>[],
          CalendarMode.antifreeze: const <SchedulePoint>[],
          CalendarMode.daily: const <SchedulePoint>[],
          CalendarMode.weekly: const <SchedulePoint>[],
        }),
      );
}
