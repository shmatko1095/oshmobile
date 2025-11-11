import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

abstract class ScheduleRepository {
  /// Fetch full calendar bundle (active mode + lists for each mode).
  Future<CalendarSnapshot> fetchAll(String deviceSn);

  /// Save full calendar bundle atomically. Optional [reqId] is echoed by device in reported.meta.lastAppliedReqId.
  Future<void> saveAll(String deviceSn, CalendarSnapshot snapshot, {String? reqId});

  /// Stream of reported updates. Key is appliedReqId (e.g. reported.meta.lastAppliedReqId), value is snapshot.
  /// If firmware doesn't provide reqId, key may be null.
  Stream<MapEntry<String?, CalendarSnapshot>> watchSnapshot(String deviceSn);

  /// Set only active mode on device (keeps lists as-is). Optional [reqId] for correlation.
  Future<void> setMode(String deviceSn, CalendarMode mode, {String? reqId});
}
