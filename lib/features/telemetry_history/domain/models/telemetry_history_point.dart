class TelemetryHistoryPoint {
  const TelemetryHistoryPoint({
    required this.bucketStart,
    required this.samplesCount,
    this.minValue,
    this.maxValue,
    this.avgValue,
    this.lastNumericValue,
    this.lastBoolValue,
    this.trueRatio,
    this.referenceSensorId,
  });

  final DateTime bucketStart;
  final int samplesCount;
  final double? minValue;
  final double? maxValue;
  final double? avgValue;
  final double? lastNumericValue;
  final bool? lastBoolValue;
  final double? trueRatio;
  final String? referenceSensorId;
}
