import 'package:flutter/material.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_activity_band.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_point.dart';

class HistoryMultiLineSeries {
  const HistoryMultiLineSeries({
    required this.id,
    required this.label,
    required this.points,
    required this.color,
    this.lineGradient,
    this.strokeWidth = 2.0,
    this.fill = false,
    this.fillTopAlpha = 0.22,
    this.fillBottomAlpha = 0.04,
    this.dashArray,
    this.includeInYAxisRange = true,
    this.activityBand,
    this.isStepLine = false,
  });

  final String id;
  final String label;
  final List<HistoryMultiLinePoint> points;
  final Color color;
  final Gradient? lineGradient;
  final double strokeWidth;
  final bool fill;
  final double fillTopAlpha;
  final double fillBottomAlpha;
  final List<int>? dashArray;
  final bool includeInYAxisRange;
  final HistoryMultiLineActivityBand? activityBand;
  final bool isStepLine;
}
