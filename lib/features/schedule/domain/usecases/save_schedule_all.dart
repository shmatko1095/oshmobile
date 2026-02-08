import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class SaveScheduleAll {
  final ScheduleRepository repo;

  const SaveScheduleAll(this.repo);

  Future<void> call(CalendarSnapshot snapshot, {String? reqId}) => repo.saveAll(snapshot, reqId: reqId);
}
