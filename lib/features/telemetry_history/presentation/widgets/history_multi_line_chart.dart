import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_chart_gap_resolver.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_activity_band.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_series.dart';

export 'history_multi_line_activity_band.dart';
export 'history_multi_line_point.dart';
export 'history_multi_line_series.dart';

part 'history_chart_point.dart';
part 'history_chart_x_window.dart';
part 'history_prepared_series.dart';
part 'history_tooltip_row.dart';
part 'history_y_axis_range.dart';

typedef HistoryMultiChartTimeLabelBuilder = String Function(DateTime timestamp);
typedef HistoryMultiChartValueLabelBuilder = String Function(double value);
typedef HistoryMultiChartTooltipValueFormatter = String Function(
  String seriesId,
  double value,
);
typedef HistoryMultiChartTooltipRangeValueFormatter = String Function(
  String seriesId,
  double value,
);

class HistoryMultiLineChart extends StatelessWidget {
  const HistoryMultiLineChart({
    super.key,
    required this.series,
    this.windowStart,
    this.windowEnd,
    this.showGrid = true,
    this.showHorizontalGrid,
    this.showVerticalGrid,
    this.showAxes = false,
    this.enableTouchTooltip = true,
    this.xAxisLabelBuilder,
    this.tooltipTimeLabelBuilder,
    this.valueLabelBuilder,
    this.tooltipValueFormatter,
    this.tooltipMinValueFormatter,
    this.tooltipAnchorSeriesId,
    this.semanticLabel,
  });

  final List<HistoryMultiLineSeries> series;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final bool showGrid;
  final bool? showHorizontalGrid;
  final bool? showVerticalGrid;
  final bool showAxes;
  final bool enableTouchTooltip;
  final HistoryMultiChartTimeLabelBuilder? xAxisLabelBuilder;
  final HistoryMultiChartTimeLabelBuilder? tooltipTimeLabelBuilder;
  final HistoryMultiChartValueLabelBuilder? valueLabelBuilder;
  final HistoryMultiChartTooltipValueFormatter? tooltipValueFormatter;
  final HistoryMultiChartTooltipRangeValueFormatter? tooltipMinValueFormatter;
  final String? tooltipAnchorSeriesId;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
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

    final xWindow = _resolveXWindow();
    final windowStartUtc = xWindow?.startUtc;
    final windowSpanSeconds = xWindow?.spanSeconds ?? 0.0;
    final useWindowAxis =
        xWindow != null && series.every((s) => s.points.isNotEmpty);

    final prepared = <_PreparedSeries>[];
    var maxX = 0.0;

    for (final line in series) {
      if (line.points.isEmpty) {
        continue;
      }

      final points = <_HistoryChartPoint>[];
      for (var i = 0; i < line.points.length; i++) {
        final sourcePoint = line.points[i];
        final ts = sourcePoint.timestamp.toUtc();
        final x = useWindowAxis
            ? _toXAxisSeconds(ts, windowStartUtc ?? ts)
            : i.toDouble();
        if (useWindowAxis && (x < 0 || x > windowSpanSeconds)) {
          continue;
        }

        double? rangeMinValue = sourcePoint.rangeMinValue;
        double? rangeMaxValue = sourcePoint.rangeMaxValue;
        if (rangeMinValue == null ||
            rangeMaxValue == null ||
            !rangeMinValue.isFinite ||
            !rangeMaxValue.isFinite ||
            rangeMinValue > rangeMaxValue) {
          rangeMinValue = null;
          rangeMaxValue = null;
        }

        points.add(
          _HistoryChartPoint(
            x: x,
            y: sourcePoint.value,
            displayY: sourcePoint.displayValue ?? sourcePoint.value,
            rangeMinY: rangeMinValue,
            rangeMaxY: rangeMaxValue,
            timestamp: ts,
            axisFraction: sourcePoint.axisFraction,
            includeInYAxisRange: sourcePoint.includeInYAxisRange,
            tooltipText: sourcePoint.tooltipText,
          ),
        );
      }

      if (points.isEmpty) {
        continue;
      }

      final spots = <FlSpot>[];
      final rangeMinSpots = <FlSpot>[];
      final rangeMaxSpots = <FlSpot>[];
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
            rangeMinSpots.add(FlSpot.nullSpot);
            rangeMaxSpots.add(FlSpot.nullSpot);
            spotToPoint.add(null);
          }
        }
        final y = point.y;
        spots.add(y == null ? FlSpot.nullSpot : FlSpot(point.x, y));
        if (point.rangeMinY != null && point.rangeMaxY != null) {
          rangeMinSpots.add(FlSpot(point.x, point.rangeMinY!));
          rangeMaxSpots.add(FlSpot(point.x, point.rangeMaxY!));
        } else {
          rangeMinSpots.add(FlSpot.nullSpot);
          rangeMaxSpots.add(FlSpot.nullSpot);
        }
        spotToPoint.add(point);
      }

      maxX = math.max(maxX, points.last.x);
      final hasBandSpots = rangeMinSpots.any((spot) => spot.isNotNull()) &&
          rangeMaxSpots.any((spot) => spot.isNotNull());
      prepared.add(
        _PreparedSeries(
          line: line,
          points: points,
          spots: spots,
          rangeMinSpots: hasBandSpots ? rangeMinSpots : null,
          rangeMaxSpots: hasBandSpots ? rangeMaxSpots : null,
          spotToPoint: spotToPoint,
        ),
      );
    }

    if (prepared.isEmpty) {
      return const SizedBox.expand();
    }

    final yValues = <double>[];
    for (final line in prepared) {
      if (!line.line.includeInYAxisRange) continue;
      yValues.addAll(
        line.points
            .where((point) => point.includeInYAxisRange && point.y != null)
            .map((point) => point.y!),
      );
      if (line.rangeMinSpots != null) {
        yValues.addAll(
          line.rangeMinSpots!
              .where((spot) => spot.isNotNull())
              .map((spot) => spot.y),
        );
      }
      if (line.rangeMaxSpots != null) {
        yValues.addAll(
          line.rangeMaxSpots!
              .where((spot) => spot.isNotNull())
              .map((spot) => spot.y),
        );
      }
    }
    if (yValues.isEmpty) {
      yValues.addAll(
        prepared.expand(
          (line) => line.points
              .where((point) => point.y != null)
              .map((point) => point.y!),
        ),
      );
    }
    if (yValues.isEmpty) {
      return const SizedBox.expand();
    }

    final minRaw = yValues.reduce(math.min);
    final maxRaw = yValues.reduce(math.max);
    final stableRange = _stableRange(minRaw, maxRaw);
    final span = (stableRange.max - stableRange.min).abs();
    final yInterval = _niceInterval(span, preferredTickCount: 4);
    final minY = _alignLower(stableRange.min, yInterval);
    final maxY = _alignUpper(stableRange.max, yInterval);
    final chartYRange = _YAxisRange(
      min: minY,
      max: maxY <= minY ? minY + 1 : maxY,
    );

    final xMax = useWindowAxis ? windowSpanSeconds : maxX;
    final xInterval = xMax <= 0 ? 1.0 : xMax / 3;

    final primaryXAxisSeries =
        prepared.reduce((a, b) => a.points.length >= b.points.length ? a : b);
    final xTickIndexes = useWindowAxis
        ? const <int>{}
        : _tickIndexes(primaryXAxisSeries.points.length, targetTickCount: 4);
    final drawHorizontalGrid = showHorizontalGrid ?? showGrid;
    final drawVerticalGrid = showVerticalGrid ?? (showGrid && showAxes);

    final lineBarsData = <LineChartBarData>[];
    final betweenBarsData = <BetweenBarsData>[];
    final chartBarToPreparedIndex = <int, int>{};
    final chartTopologyKey = ValueKey<String>(
      'history-multi-line:${prepared.map((line) => line.line.id).join('|')}',
    );

    for (var preparedIndex = 0;
        preparedIndex < prepared.length;
        preparedIndex++) {
      final line = prepared[preparedIndex];
      final mainBarIndex = lineBarsData.length;
      chartBarToPreparedIndex[mainBarIndex] = preparedIndex;
      final spots = _renderSpots(line, chartYRange);

      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          isStepLineChart: line.line.isStepLine,
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
                line.line.color.withValues(alpha: line.line.fillTopAlpha),
                line.line.color.withValues(alpha: line.line.fillBottomAlpha),
              ],
            ),
          ),
        ),
      );

      if (line.rangeMinSpots == null || line.rangeMaxSpots == null) {
        continue;
      }

      final rangeMinBarIndex = lineBarsData.length;
      lineBarsData.add(
        LineChartBarData(
          spots: line.rangeMinSpots!,
          isCurved: false,
          color: AppPalette.transparent,
          barWidth: 0.001,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      );

      final rangeMaxBarIndex = lineBarsData.length;
      lineBarsData.add(
        LineChartBarData(
          spots: line.rangeMaxSpots!,
          isCurved: false,
          color: AppPalette.transparent,
          barWidth: 0.001,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: false,
          ),
        ),
      );

      betweenBarsData.add(
        BetweenBarsData(
          fromIndex: rangeMinBarIndex,
          toIndex: rangeMaxBarIndex,
          color: line.line.color.withValues(alpha: 0.18),
        ),
      );
    }

    final chart = LineChart(
      key: chartTopologyKey,
      LineChartData(
        minX: 0,
        maxX: xMax <= 0 ? 1 : xMax,
        minY: minY,
        maxY: chartYRange.max,
        clipData: const FlClipData.all(),
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
            right: const BorderSide(color: AppPalette.transparent, width: 0),
            top: const BorderSide(color: AppPalette.transparent, width: 0),
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
              for (final touched in touchedSpots) {
                final preparedIndex = chartBarToPreparedIndex[touched.barIndex];
                if (preparedIndex == null) {
                  continue;
                }
                final line = prepared[preparedIndex];
                final spotIndex = touched.spotIndex;
                if (spotIndex < 0 || spotIndex >= line.spotToPoint.length) {
                  continue;
                }
                final point = line.spotToPoint[spotIndex];
                if (point == null) {
                  continue;
                }
                rows.add(
                  _TooltipRow(
                    seriesId: line.line.id,
                    seriesLabel: line.line.label,
                    value: point.displayY,
                    minValue: point.rangeMinY,
                    color: line.line.color,
                    timestamp: point.timestamp,
                    tooltipText: point.tooltipText,
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

              _TooltipRow? anchor;
              final anchorSeriesId = tooltipAnchorSeriesId;
              if (anchorSeriesId == null) {
                anchor = rows.first;
              } else {
                for (final row in rows) {
                  if (row.seriesId == anchorSeriesId) {
                    anchor = row;
                    break;
                  }
                }
              }
              if (anchor == null) {
                return List<LineTooltipItem?>.filled(
                  touchedSpots.length,
                  null,
                  growable: false,
                );
              }
              final timestamp = anchor.timestamp;
              final exactRows = rows
                  .where((row) => row.timestamp == timestamp)
                  .toList(growable: false);
              final header = tooltipTimeLabelBuilder?.call(timestamp) ??
                  xAxisLabelBuilder?.call(timestamp) ??
                  _defaultTimeLabel(timestamp);
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

              for (var i = 0; i < exactRows.length; i++) {
                final row = exactRows[i];
                final valueText = row.tooltipText ??
                    tooltipValueFormatter?.call(row.seriesId, row.value!) ??
                    _formatValueLabel(row.value!);
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
                final minValue = row.minValue;
                if (minValue != null) {
                  final minValueText =
                      tooltipMinValueFormatter?.call(row.seriesId, minValue);
                  if (minValueText != null && minValueText.isNotEmpty) {
                    children.add(
                      TextSpan(
                        text: '\n$minValueText',
                        style: TextStyle(
                          color: tooltipTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                }
                if (i < exactRows.length - 1) {
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
        lineBarsData: lineBarsData,
        betweenBarsData: betweenBarsData,
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    final label = semanticLabel?.trim();
    return label == null || label.isEmpty
        ? chart
        : Semantics(label: label, child: chart);
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

List<FlSpot> _renderSpots(
  _PreparedSeries series,
  _YAxisRange yAxisRange,
) {
  return List<FlSpot>.generate(
    series.spots.length,
    (index) {
      final spot = series.spots[index];
      final point = series.spotToPoint[index];
      if (spot.isNull() || point == null || point.y == null) {
        return FlSpot.nullSpot;
      }
      final axisFraction = point.axisFraction;
      if (axisFraction != null) {
        final span = math.max((yAxisRange.max - yAxisRange.min).abs(), 1.0);
        return FlSpot(
          spot.x,
          yAxisRange.min + span * axisFraction.clamp(0.0, 1.0),
        );
      }
      final activityBand = series.line.activityBand;
      if (activityBand != null) {
        return FlSpot(
          spot.x,
          _activityBandY(point.y!, yAxisRange, activityBand),
        );
      }
      return spot;
    },
  ).toList(growable: false);
}

double _activityBandY(
  double value,
  _YAxisRange yAxisRange,
  HistoryMultiLineActivityBand activityBand,
) {
  final span = math.max((yAxisRange.max - yAxisRange.min).abs(), 1.0);
  final bottomFraction = activityBand.bottomFraction.clamp(0.0, 1.0);
  final heightFraction = activityBand.heightFraction.clamp(
    0.0,
    1.0 - bottomFraction,
  );
  final lower = yAxisRange.min + span * bottomFraction;
  final upper = lower + span * heightFraction;
  return lower + value.clamp(0.0, 1.0) * (upper - lower);
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
