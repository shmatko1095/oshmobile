import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_point.dart';

class TelemetrySetpointHistory {
  const TelemetrySetpointHistory({
    required this.deviceId,
    required this.serial,
    required this.resolution,
    required this.from,
    required this.to,
    required this.points,
  });

  final String deviceId;
  final String serial;
  final String resolution;
  final DateTime from;
  final DateTime to;
  final List<TelemetrySetpointPoint> points;
}
