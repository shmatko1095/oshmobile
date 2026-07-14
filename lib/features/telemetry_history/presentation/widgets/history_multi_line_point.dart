class HistoryMultiLinePoint {
  const HistoryMultiLinePoint({
    required this.timestamp,
    required this.value,
    this.displayValue,
    this.rangeMinValue,
    this.rangeMaxValue,
    this.axisFraction,
    this.includeInYAxisRange = true,
    this.tooltipText,
  });

  final DateTime timestamp;
  final double? value;
  final double? displayValue;
  final double? rangeMinValue;
  final double? rangeMaxValue;
  final double? axisFraction;
  final bool includeInYAxisRange;
  final String? tooltipText;
}
