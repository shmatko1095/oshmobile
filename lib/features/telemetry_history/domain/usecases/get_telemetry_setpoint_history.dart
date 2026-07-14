import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';
import 'package:oshmobile/features/telemetry_history/domain/repositories/telemetry_history_repository.dart';

class GetTelemetrySetpointHistory {
  const GetTelemetrySetpointHistory({
    required TelemetryHistoryRepository repository,
  }) : _repository = repository;

  final TelemetryHistoryRepository _repository;

  Future<TelemetrySetpointHistory> call({
    required String serial,
    required TelemetryHistoryQuery query,
  }) {
    return _repository.getSetpointHistory(serial: serial, query: query);
  }
}
