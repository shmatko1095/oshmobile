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
    this.subtitle,
  });

  final String title;
  final String seriesKey;
  final TelemetryHistoryMetricKind kind;
  final String unit;
  final String? subtitle;
}
