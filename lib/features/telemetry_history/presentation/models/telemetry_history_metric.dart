enum TelemetryHistoryMetricKind {
  numeric,
  boolean,
}

class TelemetryHistoryMetric {
  const TelemetryHistoryMetric({
    required this.title,
    required this.seriesKey,
    required this.kind,
    this.unit = '',
    this.fractionDigits = 1,
    this.useSumValue = false,
    this.valueMultiplier = 1.0,
    this.subtitle,
    this.sensorId,
    this.isPrimarySensor = false,
  });

  final String title;
  final String seriesKey;
  final TelemetryHistoryMetricKind kind;
  final String unit;
  final int fractionDigits;
  final bool useSumValue;
  final double valueMultiplier;
  final String? subtitle;
  final String? sensorId;
  final bool isPrimarySensor;
}
