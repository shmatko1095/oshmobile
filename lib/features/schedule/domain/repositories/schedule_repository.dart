import 'dart:async';

import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

abstract class ScheduleRepository {
  /// Fetch full calendar bundle (active mode + lists for each mode).
  Future<CalendarSnapshot> fetchAll(String deviceSn);

  /// Save full calendar bundle atomically.
  Future<void> saveAll(String deviceSn, CalendarSnapshot snapshot);

  /// Stream the latest reported snapshot in real-time (retained + updates).
  /// MUST emit the retained snapshot immediately after first subscribe.
  Stream<CalendarSnapshot> watchSnapshot(String deviceSn);

  /// Set only active mode on device (keeps lists as-is).
  Future<void> setMode(String deviceSn, CalendarMode mode);
}
