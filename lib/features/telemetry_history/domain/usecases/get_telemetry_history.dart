import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/repositories/telemetry_history_repository.dart';

class GetTelemetryHistory {
  const GetTelemetryHistory({required TelemetryHistoryRepository repository})
      : _repository = repository;

  final TelemetryHistoryRepository _repository;

  Future<TelemetryHistorySeries> call({
    required String serial,
    required TelemetryHistoryQuery query,
  }) {
    return _repository.getSeries(serial: serial, query: query);
  }
}
