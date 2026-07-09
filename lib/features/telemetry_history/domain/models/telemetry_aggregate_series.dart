class TelemetryAggregateSeries {
  const TelemetryAggregateSeries({
    required this.seriesKey,
    required this.valueType,
    required this.unit,
    required this.samplesCount,
    this.minValue,
    this.maxValue,
    this.avgValue,
    this.sumValue,
    this.lastNumericValue,
    this.trueCount = 0,
    this.trueRatio,
    this.lastBoolValue,
  });

  final String seriesKey;
  final String valueType;
  final String unit;
  final int samplesCount;
  final double? minValue;
  final double? maxValue;
  final double? avgValue;
  final double? sumValue;
  final double? lastNumericValue;
  final int trueCount;
  final double? trueRatio;
  final bool? lastBoolValue;
}
