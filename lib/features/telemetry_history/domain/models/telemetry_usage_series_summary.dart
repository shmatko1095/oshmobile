class TelemetryUsageSeriesSummary {
  const TelemetryUsageSeriesSummary({
    required this.coverageRatio,
    required this.availableFrom,
    this.total,
    this.average,
    this.peak,
    this.minimum,
    this.maximum,
  });

  final double coverageRatio;
  final DateTime? availableFrom;
  final double? total;
  final double? average;
  final double? peak;
  final double? minimum;
  final double? maximum;
}
