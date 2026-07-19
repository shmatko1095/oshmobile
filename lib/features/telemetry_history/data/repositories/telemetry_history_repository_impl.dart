import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/repositories/telemetry_history_repository.dart';

class TelemetryHistoryRepositoryImpl implements TelemetryHistoryRepository {
  const TelemetryHistoryRepositoryImpl({
    required TelemetryHistoryRemoteDataSource remote,
  }) : _remote = remote;

  final TelemetryHistoryRemoteDataSource _remote;

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String serial,
    required TelemetryHistoryQuery query,
  }) {
    return _remote.getSeries(serial: serial, query: query);
  }

  @override
  Future<TelemetryAggregate> getAggregate({
    required String serial,
    required TelemetryAggregateQuery query,
  }) {
    return _remote.getAggregate(serial: serial, query: query);
  }

  @override
  Future<TelemetrySetpointHistory> getSetpointHistory({
    required String serial,
    required TelemetryHistoryQuery query,
  }) {
    return _remote.getSetpointHistory(serial: serial, query: query);
  }

  @override
  Future<EnergyUsage> getEnergyUsage({
    required String serial,
    required TelemetryUsageQuery query,
  }) {
    return _remote.getEnergyUsage(serial: serial, query: query);
  }

  @override
  Future<HeatingUsage> getHeatingUsage({
    required String serial,
    required TelemetryUsageQuery query,
  }) {
    return _remote.getHeatingUsage(serial: serial, query: query);
  }
}
