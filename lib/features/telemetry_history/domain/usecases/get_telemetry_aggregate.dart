import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/repositories/telemetry_history_repository.dart';

class GetTelemetryAggregate {
  const GetTelemetryAggregate({
    required TelemetryHistoryRepository repository,
  }) : _repository = repository;

  final TelemetryHistoryRepository _repository;

  Future<TelemetryAggregate> call({
    required String serial,
    required TelemetryAggregateQuery query,
  }) {
    return _repository.getAggregate(serial: serial, query: query);
  }
}
