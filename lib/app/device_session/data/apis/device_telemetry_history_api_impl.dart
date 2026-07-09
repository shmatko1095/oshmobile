import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_history.dart';

class DeviceTelemetryHistoryApiImpl implements DeviceTelemetryHistoryApi {
  const DeviceTelemetryHistoryApiImpl({
    required String deviceSn,
    required GetTelemetryHistory getTelemetryHistory,
    required GetTelemetryAggregate getTelemetryAggregate,
  })  : _deviceSn = deviceSn,
        _getTelemetryHistory = getTelemetryHistory,
        _getTelemetryAggregate = getTelemetryAggregate;

  final String _deviceSn;
  final GetTelemetryHistory _getTelemetryHistory;
  final GetTelemetryAggregate _getTelemetryAggregate;

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
}
