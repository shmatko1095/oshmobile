part of 'telemetry_history_slide_view_model.dart';

class TelemetryHistoryMetricValueFormatter {
  const TelemetryHistoryMetricValueFormatter._();

  static String format(double value, TelemetryHistoryMetric metric) {
    if (metric.kind == TelemetryHistoryMetricKind.boolean) {
      return '${(value * 100).round()}%';
    }
    final unit = metric.unit.isEmpty ? '' : ' ${metric.unit}';
    return '${value.toStringAsFixed(metric.fractionDigits)}$unit';
  }
}
