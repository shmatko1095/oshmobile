part of 'telemetry_history_slide_view_model.dart';

class TelemetryHistoryChartEntry {
  const TelemetryHistoryChartEntry({
    required this.timestamp,
    required this.value,
    this.rangeMinValue,
    this.rangeMaxValue,
    this.referenceSensorId,
  });

  final DateTime timestamp;
  final double value;
  final double? rangeMinValue;
  final double? rangeMaxValue;
  final String? referenceSensorId;
}
