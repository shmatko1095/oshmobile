part of 'history_multi_line_chart.dart';

class _PreparedSeries {
  const _PreparedSeries({
    required this.line,
    required this.points,
    required this.spots,
    required this.rangeMinSpots,
    required this.rangeMaxSpots,
    required this.spotToPoint,
  });

  final HistoryMultiLineSeries line;
  final List<_HistoryChartPoint> points;
  final List<FlSpot> spots;
  final List<FlSpot>? rangeMinSpots;
  final List<FlSpot>? rangeMaxSpots;
  final List<_HistoryChartPoint?> spotToPoint;
}
