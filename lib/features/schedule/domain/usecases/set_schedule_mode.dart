import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class SetScheduleMode {
  final ScheduleRepository repo;
  const SetScheduleMode(this.repo);

  Future<void> call(String deviceSn, CalendarMode mode) => repo.setMode(deviceSn, mode);
}
