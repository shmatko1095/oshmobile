import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_quality.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_state.dart';

class TelemetrySetpointPoint {
  const TelemetrySetpointPoint({
    required this.bucketStart,
    required this.observedAt,
    required this.state,
    required this.quality,
  });

  final DateTime bucketStart;
  final DateTime observedAt;
  final TelemetrySetpointState state;
  final TelemetrySetpointQuality quality;
}
