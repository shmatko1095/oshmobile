import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';

class TelemetryHistorySeries {
  const TelemetryHistorySeries({
    required this.deviceId,
    required this.serial,
    required this.seriesKey,
    required this.resolution,
    required this.from,
    required this.to,
    required this.points,
  });

  final String deviceId;
  final String serial;
  final String seriesKey;
  final String resolution;
  final DateTime from;
  final DateTime to;
  final List<TelemetryHistoryPoint> points;
}
