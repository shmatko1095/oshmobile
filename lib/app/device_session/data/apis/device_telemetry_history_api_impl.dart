import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_history.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_setpoint_history.dart';

class DeviceTelemetryHistoryApiImpl implements DeviceTelemetryHistoryApi {
  const DeviceTelemetryHistoryApiImpl({
    required String deviceSn,
    required GetTelemetryHistory getTelemetryHistory,
    required GetTelemetryAggregate getTelemetryAggregate,
    required GetTelemetrySetpointHistory getTelemetrySetpointHistory,
  })  : _deviceSn = deviceSn,
        _getTelemetryHistory = getTelemetryHistory,
        _getTelemetryAggregate = getTelemetryAggregate,
        _getTelemetrySetpointHistory = getTelemetrySetpointHistory;

  final String _deviceSn;
  final GetTelemetryHistory _getTelemetryHistory;
  final GetTelemetryAggregate _getTelemetryAggregate;
  final GetTelemetrySetpointHistory _getTelemetrySetpointHistory;

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) {
    return _getTelemetryHistory(
      serial: _deviceSn,
      query: TelemetryHistoryQuery(
        seriesKey: seriesKey,
        from: from,
        to: to,
        preferredResolution: preferredResolution,
        apiVersion: apiVersion,
      ),
    );
  }

  @override
  Future<TelemetryAggregate> getAggregate({
    required TelemetryAggregateQuery query,
  }) {
    return _getTelemetryAggregate(serial: _deviceSn, query: query);
  }

  @override
  Future<TelemetrySetpointHistory> getSetpointHistory({
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
  }) {
    return _getTelemetrySetpointHistory(
      serial: _deviceSn,
      query: TelemetryHistoryQuery(
        seriesKey: 'thermostat_setpoint',
        from: from,
        to: to,
        preferredResolution: preferredResolution,
      ),
    );
  }
}
