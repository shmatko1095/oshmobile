import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';

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

  Future<EnergyUsage> getEnergyUsage({
    required String serial,
    required TelemetryUsageQuery query,
  });

  Future<HeatingUsage> getHeatingUsage({
    required String serial,
    required TelemetryUsageQuery query,
  });
}
