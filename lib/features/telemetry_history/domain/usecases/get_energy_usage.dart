import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/repositories/telemetry_history_repository.dart';

class GetEnergyUsage {
  const GetEnergyUsage({required TelemetryHistoryRepository repository})
      : _repository = repository;

  final TelemetryHistoryRepository _repository;

  Future<EnergyUsage> call({
    required String serial,
    required TelemetryUsageQuery query,
  }) {
    return _repository.getEnergyUsage(serial: serial, query: query);
  }
}
