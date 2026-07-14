part of 'history_multi_line_chart.dart';

class _HistoryChartPoint {
  const _HistoryChartPoint({
    required this.x,
    required this.y,
    required this.displayY,
    required this.rangeMinY,
    required this.rangeMaxY,
    required this.timestamp,
    required this.axisFraction,
    required this.includeInYAxisRange,
    required this.tooltipText,
  });

  final double x;
  final double? y;
  final double? displayY;
  final double? rangeMinY;
  final double? rangeMaxY;
  final DateTime timestamp;
  final double? axisFraction;
  final bool includeInYAxisRange;
  final String? tooltipText;
}
