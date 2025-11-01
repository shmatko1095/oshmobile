import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class FetchScheduleAll {
  final ScheduleRepository repo;

  const FetchScheduleAll(this.repo);

  Future<CalendarSnapshot> call(String deviceSn) => repo.fetchAll(deviceSn);
}
