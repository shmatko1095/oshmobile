import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

typedef HistoryBarChartValueLabelBuilder = String Function(double value);
typedef HistoryBarChartTimeLabelBuilder = String Function(DateTime timestamp);

class HistoryBarChart extends StatelessWidget {
  const HistoryBarChart({
    super.key,
    required this.values,
    required this.timestamps,
    this.windowStart,
    this.windowEnd,
    this.color = AppPalette.accentSuccess,
    this.showGrid = true,
    this.showHorizontalGrid,
    this.showVerticalGrid,
    this.showAxes = false,
    this.enableTouchTooltip = true,
    this.valueLabelBuilder,
    this.xAxisLabelBuilder,
    this.tooltipTimeLabelBuilder,
    this.semanticLabel,
  });

  final List<double?> values;
  final List<DateTime> timestamps;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final Color color;
  final bool showGrid;
  final bool? showHorizontalGrid;
  final bool? showVerticalGrid;
  final bool showAxes;
  final bool enableTouchTooltip;
  final HistoryBarChartValueLabelBuilder? valueLabelBuilder;
  final HistoryBarChartTimeLabelBuilder? xAxisLabelBuilder;
  final HistoryBarChartTimeLabelBuilder? tooltipTimeLabelBuilder;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || timestamps.length != values.length) {
      return const SizedBox.expand();
    }

    final points = _preparePoints();
    if (points.isEmpty) {
      return const SizedBox.expand();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final axisMutedColor =
        isDark ? AppPalette.textMuted : AppPalette.lightTextSubtle;
    final separatorColor =
        isDark ? AppPalette.separator : AppPalette.lightBorder;
    final axisBorderColor =
        isDark ? AppPalette.borderSoft : AppPalette.lightBorder;
    final tooltipBackground = isDark
        ? AppPalette.tooltipDarkSurface.withValues(alpha: 0.96)
        : AppPalette.white.withValues(alpha: 0.96);
    final tooltipTextColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextPrimary;
    final tooltipStrokeColor = isDark
        ? AppPalette.white.withValues(alpha: 0.95)
        : AppPalette.lightBorderSubtle;

    final yValues = points
        .map((point) => point.value)
        .whereType<double>()
        .toList(growable: false);
    if (yValues.isEmpty) {
      return const SizedBox.expand();
    }
    final maxRaw = yValues.reduce(math.max);
    final yInterval = _niceInterval(
      maxRaw <= 0 ? 1 : maxRaw,
      preferredTickCount: 4,
    );
    final maxY = _alignUpper(maxRaw <= 0 ? 1 : maxRaw, yInterval);
    final xInterval =
        points.length <= 1 ? 1.0 : math.max(1.0, (points.length - 1) / 3);
    final xTickIndexes = _tickIndexes(points.length, targetTickCount: 4);
    final barWidth = _barWidth(points.length);
    final drawHorizontalGrid = showHorizontalGrid ?? showGrid;
    final drawVerticalGrid = showVerticalGrid ?? (showGrid && showAxes);

    final groups = <BarChartGroupData>[
      for (var i = 0; i < points.length; i++)
        BarChartGroupData(
          x: i,
          barRods: <BarChartRodData>[
            BarChartRodData(
              toY: points[i].value ?? 0,
              width: barWidth,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              gradient: points[i].value == null
                  ? const LinearGradient(
                      colors: <Color>[
                        AppPalette.transparent,
                        AppPalette.transparent,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: <Color>[
                        color.withValues(alpha: 0.22),
                        color.withValues(alpha: 0.72),
                      ],
                    ),
            ),
          ],
        ),
    ];

    final total = yValues.fold<double>(0, (sum, value) => sum + value);
    return Semantics(
      label: semanticLabel,
      value: _formatValueLabel(total),
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY <= 0 ? 1 : maxY,
          alignment: BarChartAlignment.spaceBetween,
          groupsSpace: 2,
          barGroups: groups,
          gridData: FlGridData(
            show: drawHorizontalGrid || drawVerticalGrid,
            drawHorizontalLine: drawHorizontalGrid,
            drawVerticalLine: drawVerticalGrid,
            horizontalInterval: yInterval,
            verticalInterval: xInterval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: separatorColor.withValues(alpha: isDark ? 0.12 : 0.18),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (_) => FlLine(
              color: separatorColor.withValues(alpha: isDark ? 0.08 : 0.12),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showAxes,
                reservedSize: 64,
                interval: yInterval,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _formatValueLabel(value),
                    style: TextStyle(
                      color: axisMutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: showAxes,
                reservedSize: 28,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if ((value - index).abs() > 0.2 ||
                      index < 0 ||
                      index >= points.length ||
                      !xTickIndexes.contains(index)) {
                    return const SizedBox.shrink();
                  }
                  final label =
                      xAxisLabelBuilder?.call(points[index].timestamp) ??
                          _defaultTimeLabel(points[index].timestamp);
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(
                      meta,
                      distanceFromEdge: 6,
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: axisMutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: showAxes,
            border: Border(
              left: BorderSide(
                color: axisBorderColor,
                width: 1,
              ),
              bottom: BorderSide(
                color: axisBorderColor,
                width: 1,
              ),
              right: const BorderSide(
                color: AppPalette.transparent,
                width: 0,
              ),
              top: const BorderSide(
                color: AppPalette.transparent,
                width: 0,
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: enableTouchTooltip,
            handleBuiltInTouches: enableTouchTooltip,
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipBorder: BorderSide(
                color: tooltipStrokeColor.withValues(alpha: 0.55),
              ),
              maxContentWidth: 180,
              getTooltipColor: (_) => tooltipBackground,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final index = group.x;
                if (index < 0 || index >= points.length) return null;
                final point = points[index];
                if (point.value == null) return null;
                final header = tooltipTimeLabelBuilder?.call(point.timestamp) ??
                    xAxisLabelBuilder?.call(point.timestamp) ??
                    _defaultTimeLabel(point.timestamp);
                return BarTooltipItem(
                  '',
                  TextStyle(
                    color: tooltipTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '$header\n',
                      style: TextStyle(
                        color: tooltipTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: _formatValueLabel(point.value!),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  List<_HistoryBarPoint> _preparePoints() {
    final startUtc = windowStart?.toUtc();
    final endUtc = windowEnd?.toUtc();
    final hasWindow =
        startUtc != null && endUtc != null && endUtc.isAfter(startUtc);
    final points = <_HistoryBarPoint>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value != null && !value.isFinite) continue;
      final timestamp = timestamps[i].toUtc();
      if (hasWindow &&
          (timestamp.isBefore(startUtc) || timestamp.isAfter(endUtc))) {
        continue;
      }
      points.add(
        _HistoryBarPoint(
          value: value == null ? null : math.max(0, value),
          timestamp: timestamp,
        ),
      );
    }
    return points;
  }

  String _defaultTimeLabel(DateTime timestamp) {
    final t = timestamp.toLocal();
    final mm = t.month.toString().padLeft(2, '0');
    final dd = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    return '$mm/$dd $hh:$min';
  }

  String _formatValueLabel(double value) {
    if (valueLabelBuilder != null) {
      return valueLabelBuilder!(value);
    }
    final rounded = value.roundToDouble();
    if ((rounded - value).abs() < 0.0001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _HistoryBarPoint {
  const _HistoryBarPoint({
    required this.value,
    required this.timestamp,
  });

  final double? value;
  final DateTime timestamp;
}

Set<int> _tickIndexes(int count, {required int targetTickCount}) {
  if (count <= 1) return const <int>{0};
  final safeTarget = targetTickCount < 2 ? 2 : targetTickCount;
  final result = <int>{0, count - 1};
  final steps = safeTarget - 1;
  for (var i = 1; i < steps; i++) {
    final index = ((count - 1) * i / steps).round();
    result.add(index);
  }
  return result;
}

double _niceInterval(double span, {required int preferredTickCount}) {
  if (span <= 0.000001) return 1;
  final rough = span / preferredTickCount;
  final exponent = math.pow(10.0, (math.log(rough) / math.ln10).floor());
  final fraction = rough / exponent;
  final niceFraction = switch (fraction) {
    <= 1 => 1.0,
    <= 2 => 2.0,
    <= 5 => 5.0,
    _ => 10.0,
  };
  return niceFraction * exponent;
}

double _alignUpper(double value, double interval) {
  return (value / interval).ceilToDouble() * interval;
}

double _barWidth(int count) {
  return switch (count) {
    <= 14 => 10,
    <= 60 => 5.5,
    <= 180 => 3.2,
    _ => 2.0,
  };
}
