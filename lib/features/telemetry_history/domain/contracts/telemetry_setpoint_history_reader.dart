import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';

abstract interface class TelemetrySetpointHistoryReader {
  Future<TelemetrySetpointHistory> getSetpointHistory({
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
  });
}
