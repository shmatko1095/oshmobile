import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/usecases/get_telemetry_history.dart';

class DeviceTelemetryHistoryApiImpl implements DeviceTelemetryHistoryApi {
  const DeviceTelemetryHistoryApiImpl({
    required String deviceSn,
    required GetTelemetryHistory getTelemetryHistory,
  })  : _deviceSn = deviceSn,
        _getTelemetryHistory = getTelemetryHistory;

  final String _deviceSn;
  final GetTelemetryHistory _getTelemetryHistory;

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
}
