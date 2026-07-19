import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_series_summary.dart';

class TelemetryHistorySeries {
  const TelemetryHistorySeries({
    required this.deviceId,
    required this.serial,
    required this.seriesKey,
    required this.resolution,
    required this.from,
    required this.to,
    required this.points,
    this.usageSummary,
  });

  final String deviceId;
  final String serial;
  final String seriesKey;
  final String resolution;
  final DateTime from;
  final DateTime to;
  final List<TelemetryHistoryPoint> points;
  final TelemetryUsageSeriesSummary? usageSummary;
}
