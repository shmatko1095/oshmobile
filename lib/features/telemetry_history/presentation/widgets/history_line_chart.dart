import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

typedef HistoryChartValueLabelBuilder = String Function(double value);
typedef HistoryChartTimeLabelBuilder = String Function(DateTime timestamp);
typedef HistoryChartTooltipBuilder = String Function(
  DateTime timestamp,
  double value,
);

class HistoryLineChart extends StatelessWidget {
  const HistoryLineChart({
    super.key,
    required this.values,
    this.timestamps,
    this.windowStart,
    this.windowEnd,
    this.color = AppPalette.accentPrimary,
    this.strokeWidth = 2.0,
    this.fill = true,
    this.showGrid = true,
    this.showAxes = false,
    this.enableTouchTooltip = false,
    this.valueLabelBuilder,
    this.xAxisLabelBuilder,
    this.tooltipBuilder,
  });

  final List<double> values;
  final List<DateTime>? timestamps;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final Color color;
  final double strokeWidth;
  final bool fill;
  final bool showGrid;
  final bool showAxes;
  final bool enableTouchTooltip;
  final HistoryChartValueLabelBuilder? valueLabelBuilder;
  final HistoryChartTimeLabelBuilder? xAxisLabelBuilder;
  final HistoryChartTooltipBuilder? tooltipBuilder;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.expand();
    }

    final resolvedTimestamps = _resolvedTimestamps(values.length);
    final xWindow = _resolveXWindow();
    final useWindowAxis = xWindow != null &&
        resolvedTimestamps.every((timestamp) => timestamp != null);

    final points = <_HistoryChartPoint>[];
    for (var i = 0; i < values.length; i++) {
      final timestamp = resolvedTimestamps[i];
      if (useWindowAxis && timestamp != null) {
        final xValue = _toXAxisSeconds(
          timestamp,
          xWindow.startUtc,
        );
        // Drop out-of-range points to keep the line strictly inside
        // the requested history window.
        if (xValue < 0 || xValue > xWindow.spanSeconds) continue;
        points.add(
          _HistoryChartPoint(
            x: xValue,
            y: values[i],
            timestamp: timestamp,
          ),
        );
        continue;
      }
      points.add(
        _HistoryChartPoint(
          x: i.toDouble(),
          y: values[i],
          timestamp: timestamp,
        ),
      );
    }

    if (points.isEmpty) {
      return const SizedBox.expand();
    }

    final spots = <FlSpot>[
      for (final point in points) FlSpot(point.x, point.y),
    ];
    final minRaw = values.reduce(math.min);
    final maxRaw = values.reduce(math.max);
    final span = (maxRaw - minRaw).abs();
    final yInterval = _niceInterval(span, preferredTickCount: 4);
    final minY = _alignLower(minRaw, yInterval);
    final maxY = _alignUpper(maxRaw, yInterval);
    final maxX =
        useWindowAxis ? xWindow.spanSeconds : (points.length - 1).toDouble();
    final xInterval = maxX <= 0 ? 1.0 : maxX / 3;
    final xTickIndexes = useWindowAxis
        ? const <int>{}
        : _tickIndexes(points.length, targetTickCount: 4);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX <= 0 ? 1 : maxX,
        minY: minY,
        maxY: maxY <= minY ? minY + 1 : maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: showGrid,
          drawHorizontalLine: true,
          drawVerticalLine: showAxes,
          horizontalInterval: yInterval,
          verticalInterval: xInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppPalette.separator.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: AppPalette.separator.withValues(alpha: 0.35),
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
              reservedSize: 44,
              interval: yInterval,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  _formatValueLabel(value),
                  style: const TextStyle(
                    color: AppPalette.textMuted,
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
                late final String label;
                if (useWindowAxis) {
                  final clampedSeconds = value.clamp(0.0, xWindow.spanSeconds);
                  final timestamp = _fromXAxisSeconds(
                    xWindow.startUtc,
                    clampedSeconds,
                  );
                  label = xAxisLabelBuilder?.call(timestamp) ??
                      _defaultTimeLabel(timestamp);
                } else {
                  final index = value.round();
                  if ((value - index).abs() > 0.2 ||
                      index < 0 ||
                      index >= points.length ||
                      !xTickIndexes.contains(index)) {
                    return const SizedBox.shrink();
                  }

                  final ts = points[index].timestamp;
                  label = ts == null
                      ? index.toString()
                      : (xAxisLabelBuilder?.call(ts) ?? _defaultTimeLabel(ts));
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  fitInside: SideTitleFitInsideData.fromTitleMeta(
                    meta,
                    distanceFromEdge: 6,
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppPalette.textMuted,
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
              color: AppPalette.separator.withValues(alpha: 0.7),
              width: 1,
            ),
            bottom: BorderSide(
              color: AppPalette.separator.withValues(alpha: 0.7),
              width: 1,
            ),
            right: const BorderSide(color: Colors.transparent, width: 0),
            top: const BorderSide(color: Colors.transparent, width: 0),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: enableTouchTooltip,
          handleBuiltInTouches: enableTouchTooltip,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: color.withValues(alpha: 0.6),
                  strokeWidth: 1.2,
                  dashArray: const [4, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 1.6,
                    strokeColor: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipColor: (_) => const Color(0xFF141820).withValues(
              alpha: 0.96,
            ),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.spotIndex;
                if (index < 0 || index >= points.length) return null;
                final ts = points[index].timestamp;
                final title = ts == null
                    ? '#$index'
                    : (xAxisLabelBuilder?.call(ts) ?? _defaultTimeLabel(ts));
                final valueText = ts == null
                    ? _formatValueLabel(spot.y)
                    : (tooltipBuilder?.call(ts, spot.y) ??
                        '$title\n${_formatValueLabel(spot.y)}');
                return LineTooltipItem(
                  valueText,
                  const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: color,
            barWidth: strokeWidth,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
            belowBarData: BarAreaData(
              show: fill,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.24),
                  color.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  List<DateTime?> _resolvedTimestamps(int length) {
    final source = timestamps;
    if (source == null || source.length != length) {
      return List<DateTime?>.filled(length, null);
    }
    return source.map((v) => v.toUtc()).toList(growable: false);
  }

  _HistoryChartXWindow? _resolveXWindow() {
    final start = windowStart?.toUtc();
    final end = windowEnd?.toUtc();
    if (start == null || end == null || !end.isAfter(start)) {
      return null;
    }
    final spanSeconds = end.difference(start).inMilliseconds / 1000;
    if (spanSeconds <= 0) return null;
    return _HistoryChartXWindow(startUtc: start, spanSeconds: spanSeconds);
  }

  double _toXAxisSeconds(DateTime timestampUtc, DateTime startUtc) {
    return timestampUtc.toUtc().difference(startUtc).inMilliseconds / 1000;
  }

  DateTime _fromXAxisSeconds(DateTime startUtc, double seconds) {
    return startUtc.add(
      Duration(milliseconds: (seconds * 1000).round()),
    );
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

double _alignLower(double value, double interval) {
  return (value / interval).floorToDouble() * interval;
}

double _alignUpper(double value, double interval) {
  return (value / interval).ceilToDouble() * interval;
}

class _HistoryChartPoint {
  const _HistoryChartPoint({
    required this.x,
    required this.y,
    required this.timestamp,
  });

  final double x;
  final double y;
  final DateTime? timestamp;
}

class _HistoryChartXWindow {
  const _HistoryChartXWindow({
    required this.startUtc,
    required this.spanSeconds,
  });

  final DateTime startUtc;
  final double spanSeconds;
}
