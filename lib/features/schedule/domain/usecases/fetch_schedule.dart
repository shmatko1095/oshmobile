import 'package:oshmobile/features/schedule/data/schedule_repository.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';

/// Thin use-case: policy entrypoint. Keep it transport-agnostic.
class FetchSchedule {
  final ScheduleRepository repo;

  const FetchSchedule(this.repo);

  Future<List<SchedulePoint>> call(String deviceId, CalendarMode mode) => repo.fetchSchedule(deviceId, mode);
}
