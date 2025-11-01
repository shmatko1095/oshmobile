import 'dart:async';

import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';

abstract class ScheduleRepository {
  /// Fetch full calendar bundle (active mode + lists for each mode).
  Future<CalendarSnapshot> fetchAll(String deviceSn);

  /// Save full calendar bundle atomically.
  Future<void> saveAll(String deviceSn, CalendarSnapshot snapshot);
}
