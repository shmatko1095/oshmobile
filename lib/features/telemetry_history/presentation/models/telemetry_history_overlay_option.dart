part of 'telemetry_history_slide_view_model.dart';

class TelemetryHistoryOverlayOption {
  const TelemetryHistoryOverlayOption({
    required this.id,
    required this.label,
    required this.metric,
    required this.color,
  });

  final String id;
  final String label;
  final TelemetryHistoryMetric metric;
  final Color color;
}
