import 'package:oshmobile/features/schedule/data/schedule_repository.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

class SaveSchedule {
  final ScheduleRepository repo;

  const SaveSchedule(this.repo);

  /// Optional policy knobs can be added later (e.g., timeout).
  Future<void> call(String deviceId, CalendarMode mode, List<SchedulePoint> points) =>
      repo.saveSchedule(deviceId, mode, points);
}
