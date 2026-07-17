import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';

class TelemetryHistoryDashboardDefinition {
  const TelemetryHistoryDashboardDefinition({
    required this.metrics,
    required this.comparisonMetrics,
    required this.initialMetricIndex,
  });

  final List<TelemetryHistoryMetric> metrics;
  final List<TelemetryHistoryMetric> comparisonMetrics;
  final int initialMetricIndex;

  bool get isEmpty => metrics.isEmpty;
}
