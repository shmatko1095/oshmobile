part of 'history_multi_line_chart.dart';

class _TooltipRow {
  const _TooltipRow({
    required this.seriesId,
    required this.seriesLabel,
    required this.value,
    required this.minValue,
    required this.color,
    required this.timestamp,
    required this.tooltipText,
  });

  final String seriesId;
  final String seriesLabel;
  final double? value;
  final double? minValue;
  final Color color;
  final DateTime timestamp;
  final String? tooltipText;
}
