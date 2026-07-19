import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/repositories/telemetry_history_repository.dart';

class GetHeatingUsage {
  const GetHeatingUsage({required TelemetryHistoryRepository repository})
      : _repository = repository;

  final TelemetryHistoryRepository _repository;

  Future<HeatingUsage> call({
    required String serial,
    required TelemetryUsageQuery query,
  }) {
    return _repository.getHeatingUsage(serial: serial, query: query);
  }
}
