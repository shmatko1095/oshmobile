import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

abstract class ScheduleRepository {
  /// Fetch full calendar bundle (active mode + points for each mode).
  Future<CalendarSnapshot> fetchAll(String deviceSn, {bool forceGet = false});

  /// Save full calendar bundle atomically via JSON-RPC.
  Future<void> saveAll(String deviceSn, CalendarSnapshot snapshot, {String? reqId});

  /// Stream of retained schedule state updates (JSON-RPC notifications).
  Stream<CalendarSnapshot> watchSnapshot(String deviceSn);

  /// Set only active mode on device (keeps points as-is). Optional [reqId] for correlation.
  Future<void> setMode(String deviceSn, CalendarMode mode, {String? reqId});
}
