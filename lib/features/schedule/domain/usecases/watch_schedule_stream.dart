import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class WatchScheduleStream {
  final ScheduleRepository repo;

  const WatchScheduleStream(this.repo);

  Stream<MapEntry<String?, CalendarSnapshot>> call(String deviceSn) => repo.watchSnapshot(deviceSn);
}
