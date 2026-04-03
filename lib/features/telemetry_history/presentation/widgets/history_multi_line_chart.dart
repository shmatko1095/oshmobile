import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_chart_gap_resolver.dart';

typedef HistoryMultiChartTimeLabelBuilder = String Function(DateTime timestamp);
typedef HistoryMultiChartValueLabelBuilder = String Function(double value);
typedef HistoryMultiChartTooltipValueFormatter = String Function(
  String seriesId,
  double value,
);

class HistoryMultiLineSeries {
  const HistoryMultiLineSeries({
    required this.id,
    required this.label,
    required this.values,
    this.displayValues,
    required this.timestamps,
    required this.color,
    this.lineGradient,
    this.strokeWidth = 2.0,
    this.fill = false,
    this.dashArray,
  });

  final String id;
  final String label;
  final List<double> values;
  final List<double>? displayValues;
  final List<DateTime> timestamps;
  final Color color;
  final Gradient? lineGradient;
  final double strokeWidth;
  final bool fill;
  final List<int>? dashArray;
}

class HistoryMultiLineChart extends StatelessWidget {
  const HistoryMultiLineChart({
    super.key,
    required this.series,
    this.windowStart,
    this.windowEnd,
    this.showGrid = true,
    this.showAxes = false,
    this.enableTouchTooltip = true,
    this.xAxisLabelBuilder,
    this.tooltipTimeLabelBuilder,
    this.valueLabelBuilder,
    this.tooltipValueFormatter,
  });

  final List<HistoryMultiLineSeries> series;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final bool showGrid;
  final bool showAxes;
  final bool enableTouchTooltip;
  final HistoryMultiChartTimeLabelBuilder? xAxisLabelBuilder;
  final HistoryMultiChartTimeLabelBuilder? tooltipTimeLabelBuilder;
  final HistoryMultiChartValueLabelBuilder? valueLabelBuilder;
  final HistoryMultiChartTooltipValueFormatter? tooltipValueFormatter;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const SizedBox.expand();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final axisMutedColor =
        isDark ? AppPalette.textMuted : const Color(0xFF64748B);
    final separatorColor =
        isDark ? AppPalette.separator : const Color(0x1A0F172A);
    final axisBorderColor = isDark
        ? AppPalette.separator.withValues(alpha: 0.7)
        : const Color(0x2A0F172A);
    final tooltipBackground = isDark
        ? const Color(0xFF141820).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.96);
    final tooltipTextColor =
        isDark ? AppPalette.textPrimary : const Color(0xFF0F172A);
    final tooltipStrokeColor =
        isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFFE2E8F0);

    final xWindow = _resolveXWindow();
    final windowStartUtc = xWindow?.startUtc;
    final windowSpanSeconds = xWindow?.spanSeconds ?? 0.0;
    final useWindowAxis = xWindow != null &&
        series.every((s) =>
            s.values.isNotEmpty && s.timestamps.length == s.values.length);

    final prepared = <_PreparedSeries>[];
    var maxX = 0.0;

    for (final line in series) {
      if (line.values.isEmpty || line.timestamps.length != line.values.length) {
        continue;
      }
      final normalizedDisplayValues = line.displayValues;
      final hasCustomDisplayValues = normalizedDisplayValues != null &&
          normalizedDisplayValues.length == line.values.length;

      final points = <_HistoryChartPoint>[];
      for (var i = 0; i < line.values.length; i++) {
        final ts = line.timestamps[i].toUtc();
        final x = useWindowAxis
            ? _toXAxisSeconds(ts, windowStartUtc ?? ts)
            : i.toDouble();
        if (useWindowAxis && (x < 0 || x > windowSpanSeconds)) {
          continue;
        }
        points.add(
          _HistoryChartPoint(
            x: x,
            y: line.values[i],
            displayY: hasCustomDisplayValues
                ? normalizedDisplayValues[i]
                : line.values[i],
            timestamp: ts,
          ),
        );
      }

      if (points.isEmpty) {
        continue;
      }

      final spots = <FlSpot>[];
      final spotToPoint = <_HistoryChartPoint?>[];
      final gapThresholdSeconds =
          HistoryChartGapResolver.resolveGapThresholdSeconds(
        points.map((point) => point.timestamp).toList(growable: false),
      );

      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        if (gapThresholdSeconds != null && i > 0) {
          final previous = points[i - 1];
          final gapSeconds = HistoryChartGapResolver.secondsBetween(
            previous.timestamp,
            point.timestamp,
          );
          if (gapSeconds != null && gapSeconds > gapThresholdSeconds) {
            spots.add(FlSpot.nullSpot);
            spotToPoint.add(null);
          }
        }
        spots.add(FlSpot(point.x, point.y));
        spotToPoint.add(point);
      }

      maxX = math.max(maxX, points.last.x);
      prepared.add(
        _PreparedSeries(
          line: line,
          points: points,
          spots: spots,
          spotToPoint: spotToPoint,
        ),
      );
    }

    if (prepared.isEmpty) {
      return const SizedBox.expand();
    }

    final yValues = prepared
        .expand((line) => line.points)
        .map((point) => point.y)
        .toList(growable: false);

    final minRaw = yValues.reduce(math.min);
    final maxRaw = yValues.reduce(math.max);
    final stableRange = _stableRange(minRaw, maxRaw);
    final span = (stableRange.max - stableRange.min).abs();
    final yInterval = _niceInterval(span, preferredTickCount: 4);
    final minY = _alignLower(stableRange.min, yInterval);
    final maxY = _alignUpper(stableRange.max, yInterval);

    final xMax = useWindowAxis ? windowSpanSeconds : maxX;
    final xInterval = xMax <= 0 ? 1.0 : xMax / 3;

    final primaryXAxisSeries =
        prepared.reduce((a, b) => a.points.length >= b.points.length ? a : b);
    final xTickIndexes = useWindowAxis
        ? const <int>{}
        : _tickIndexes(primaryXAxisSeries.points.length, targetTickCount: 4);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: xMax <= 0 ? 1 : xMax,
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
            color: separatorColor.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (_) => FlLine(
            color: separatorColor.withValues(alpha: 0.35),
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
                late final String label;
                if (useWindowAxis && windowStartUtc != null) {
                  final clampedSeconds = value.clamp(0.0, windowSpanSeconds);
                  final timestamp = _fromXAxisSeconds(
                    windowStartUtc,
                    clampedSeconds,
                  );
                  label = xAxisLabelBuilder?.call(timestamp) ??
                      _defaultTimeLabel(timestamp);
                } else {
                  final index = value.round();
                  if ((value - index).abs() > 0.2 ||
                      index < 0 ||
                      index >= primaryXAxisSeries.points.length ||
                      !xTickIndexes.contains(index)) {
                    return const SizedBox.shrink();
                  }
                  final ts = primaryXAxisSeries.points[index].timestamp;
                  label = xAxisLabelBuilder?.call(ts) ?? _defaultTimeLabel(ts);
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
            right: const BorderSide(color: Colors.transparent, width: 0),
            top: const BorderSide(color: Colors.transparent, width: 0),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: enableTouchTooltip,
          handleBuiltInTouches: enableTouchTooltip,
          getTouchedSpotIndicator: (barData, spotIndexes) {
            if (!enableTouchTooltip) {
              return const <TouchedSpotIndicatorData>[];
            }
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: barData.color?.withValues(alpha: 0.6) ??
                      AppPalette.accentPrimary.withValues(alpha: 0.6),
                  strokeWidth: 1.2,
                  dashArray: const <int>[4, 3],
                ),
                FlDotData(
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: bar.color ?? AppPalette.accentPrimary,
                    strokeWidth: 1.6,
                    strokeColor: tooltipStrokeColor,
                  ),
                ),
              );
            }).toList(growable: false);
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipColor: (_) => tooltipBackground,
            getTooltipItems: (touchedSpots) {
              if (!enableTouchTooltip || touchedSpots.isEmpty) {
                return const <LineTooltipItem?>[];
              }

              final rows = <_TooltipRow>[];
              DateTime? tooltipTimestamp;
              for (final touched in touchedSpots) {
                if (touched.barIndex < 0 ||
                    touched.barIndex >= prepared.length) {
                  continue;
                }
                final line = prepared[touched.barIndex];
                final spotIndex = touched.spotIndex;
                if (spotIndex < 0 || spotIndex >= line.spotToPoint.length) {
                  continue;
                }
                final point = line.spotToPoint[spotIndex];
                if (point == null) {
                  continue;
                }
                tooltipTimestamp ??= point.timestamp;
                rows.add(
                  _TooltipRow(
                    seriesId: line.line.id,
                    seriesLabel: line.line.label,
                    value: point.displayY,
                    color: line.line.color,
                  ),
                );
              }

              if (rows.isEmpty) {
                return List<LineTooltipItem?>.filled(
                  touchedSpots.length,
                  null,
                  growable: false,
                );
              }

              final timestamp = tooltipTimestamp;
              final header = timestamp == null
                  ? ''
                  : (tooltipTimeLabelBuilder?.call(timestamp) ??
                      xAxisLabelBuilder?.call(timestamp) ??
                      _defaultTimeLabel(timestamp));
              final children = <TextSpan>[];
              if (header.isNotEmpty) {
                children.add(
                  TextSpan(
                    text: '$header\n',
                    style: TextStyle(
                      color: tooltipTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }

              for (var i = 0; i < rows.length; i++) {
                final row = rows[i];
                final valueText =
                    tooltipValueFormatter?.call(row.seriesId, row.value) ??
                        _formatValueLabel(row.value);
                children.add(
                  TextSpan(
                    text: '${row.seriesLabel}: $valueText',
                    style: TextStyle(
                      color: row.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
                if (i < rows.length - 1) {
                  children.add(const TextSpan(text: '\n'));
                }
              }

              final items = List<LineTooltipItem?>.filled(
                touchedSpots.length,
                null,
                growable: false,
              );
              items[0] = LineTooltipItem(
                '',
                TextStyle(
                  color: tooltipTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                children: children,
              );
              return items;
            },
          ),
        ),
        lineBarsData: prepared
            .map(
              (line) => LineChartBarData(
                spots: line.spots,
                isCurved: false,
                color: line.line.lineGradient == null ? line.line.color : null,
                gradient: line.line.lineGradient,
                barWidth: line.line.strokeWidth,
                isStrokeCapRound: true,
                dashArray: line.line.dashArray,
                dotData: FlDotData(
                  show: false,
                ),
                belowBarData: BarAreaData(
                  show: line.line.fill,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      line.line.color.withValues(alpha: 0.18),
                      line.line.color.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
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

class _PreparedSeries {
  const _PreparedSeries({
    required this.line,
    required this.points,
    required this.spots,
    required this.spotToPoint,
  });

  final HistoryMultiLineSeries line;
  final List<_HistoryChartPoint> points;
  final List<FlSpot> spots;
  final List<_HistoryChartPoint?> spotToPoint;
}

class _HistoryChartPoint {
  const _HistoryChartPoint({
    required this.x,
    required this.y,
    required this.displayY,
    required this.timestamp,
  });

  final double x;
  final double y;
  final double displayY;
  final DateTime timestamp;
}

class _TooltipRow {
  const _TooltipRow({
    required this.seriesId,
    required this.seriesLabel,
    required this.value,
    required this.color,
  });

  final String seriesId;
  final String seriesLabel;
  final double value;
  final Color color;
}

class _HistoryChartXWindow {
  const _HistoryChartXWindow({
    required this.startUtc,
    required this.spanSeconds,
  });

  final DateTime startUtc;
  final double spanSeconds;
}

class _YAxisRange {
  const _YAxisRange({
    required this.min,
    required this.max,
  });

  final double min;
  final double max;
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

_YAxisRange _stableRange(double minRaw, double maxRaw) {
  final span = (maxRaw - minRaw).abs();
  if (span > 0.0001) {
    return _YAxisRange(min: minRaw, max: maxRaw);
  }
  final pad = math.max(minRaw.abs() * 0.04, 1.0);
  return _YAxisRange(min: minRaw - pad, max: maxRaw + pad);
}
