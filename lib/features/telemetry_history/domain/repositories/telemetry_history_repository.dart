import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';

abstract interface class TelemetryHistoryRepository {
  Future<TelemetryHistorySeries> getSeries({
    required String serial,
    required TelemetryHistoryQuery query,
  });

  Future<TelemetryAggregate> getAggregate({
    required String serial,
    required TelemetryAggregateQuery query,
  });

  Future<TelemetrySetpointHistory> getSetpointHistory({
    required String serial,
    required TelemetryHistoryQuery query,
  });
}
