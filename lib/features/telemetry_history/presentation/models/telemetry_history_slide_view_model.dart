import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_kind.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_activity_band.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_point.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_series.dart';
import 'package:oshmobile/generated/l10n.dart';

part 'telemetry_history_chart_entry.dart';
part 'telemetry_history_metric_value_formatter.dart';
part 'telemetry_history_overlay_option.dart';
part 'telemetry_history_slide_chart_kind.dart';
part 'telemetry_history_slide_view_model_data.dart';
part 'telemetry_history_summary_item.dart';

class TelemetryHistorySlideModelBuilder {
  const TelemetryHistorySlideModelBuilder._();

  static const String temperatureSeriesId = 'temp';
  static const String targetSeriesId = 'target';
  static const String heatingSeriesId = 'heating';
  static const double _maxTemperatureSetpoint = 40.0;
  static const double _onSetpointChartValue = _maxTemperatureSetpoint + 1.0;
  static const double _offSetpointAxisFraction = 0.02;
  static const Color _tempInactiveColor = AppPalette.chartTempInactive;

  static TelemetryHistorySlideViewModel build({
    required TelemetryHistoryState state,
    required TelemetryHistoryMetric metric,
    required Set<String> enabledTemperatureSeries,
    required S s,
  }) {
    final isTemperatureOverlayMode =
        isTemperatureMetric(metric) && state.hasComparisonMetrics;
    final targetMetric = _findComparisonMetric(
      state,
      TelemetryHistoryMetricCatalog.targetTemp,
    );
    final heatingMetric = _findComparisonMetric(state, 'heater_enabled');
    final overlayOptions = isTemperatureOverlayMode
        ? <TelemetryHistoryOverlayOption>[
            if (heatingMetric != null)
              TelemetryHistoryOverlayOption(
                id: heatingSeriesId,
                label: heatingMetric.title,
                metric: heatingMetric,
                color: AppPalette.accentWarning,
              ),
            if (targetMetric != null)
              TelemetryHistoryOverlayOption(
                id: targetSeriesId,
                label: targetMetric.title,
                metric: targetMetric,
                color: AppPalette.historyTarget,
              ),
          ]
        : const <TelemetryHistoryOverlayOption>[];
    final selectedOverlayIds = _selectedTemperatureToggleIds(
      overlayOptions,
      enabledTemperatureSeries,
    );
    final overlayMetricById = <String, TelemetryHistoryMetric>{
      temperatureSeriesId: metric,
      for (final option in overlayOptions) option.id: option.metric,
    };

    final series = state.seriesFor(metric);
    final isLoading = state.isLoadingFor(metric);
    final errorMessage = state.errorFor(metric);
    final entries = chartEntries(series, metric);
    final chartValues =
        entries.map((entry) => entry.value).toList(growable: false);
    final chartRangeMinValues =
        entries.map((entry) => entry.rangeMinValue).toList(growable: false);
    final chartRangeMaxValues =
        entries.map((entry) => entry.rangeMaxValue).toList(growable: false);
    final chartTimestamps =
        entries.map((entry) => entry.timestamp).toList(growable: false);
    final isUsageBar = metric.displayMode ==
            TelemetryHistoryMetricDisplayMode.energyUsage ||
        metric.displayMode == TelemetryHistoryMetricDisplayMode.heatingUsage;
    final usageBarValues = !isUsageBar
        ? const <double?>[]
        : series?.points
                .map((point) => metric.displayMode ==
                        TelemetryHistoryMetricDisplayMode.energyUsage
                    ? point.sumValue
                    : point.lastNumericValue)
                .toList(growable: false) ??
            const <double?>[];
    final usageBarTimestamps = !isUsageBar
        ? const <DateTime>[]
        : series?.points
                .map((point) => point.bucketStart)
                .toList(growable: false) ??
            const <DateTime>[];
    final summaryItems = _summaryItems(
      chartValues,
      metric,
      s,
      series: series,
      rangeDays: state.window.durationDays,
    );
    final sensorName = (metric.subtitle ?? '').trim();
    final hasSensorIdentity = sensorName.isNotEmpty && metric.sensorId != null;

    final setpointPoints = _setpointPoints(state);
    final heatingEntries = heatingMetric == null
        ? const <TelemetryHistoryChartEntry>[]
        : chartEntries(state.seriesFor(heatingMetric), heatingMetric);

    final hasTemperatureAxisSeries = entries.isNotEmpty ||
        (selectedOverlayIds.contains(targetSeriesId) &&
            setpointPoints.any(
              (point) => point.value != null && point.includeInYAxisRange,
            ));
    final overlaySeries = _overlaySeries(
      metric: metric,
      entries: entries,
      overlayOptions: overlayOptions,
      selectedOverlayIds: selectedOverlayIds,
      setpointPoints: setpointPoints,
      heatingEntries: heatingEntries,
      hasTemperatureAxisSeries: hasTemperatureAxisSeries,
      windowStart: series?.from,
      windowEnd: series?.to,
    );
    final selectedOverlayMetrics = overlayOptions
        .where((option) => selectedOverlayIds.contains(option.id))
        .map((option) => option.metric)
        .toList(growable: false);
    final overlayLoading = selectedOverlayMetrics.any(
      (overlayMetric) =>
          overlayMetric.seriesKey == TelemetryHistoryMetricCatalog.targetTemp
              ? state.setpointLoading
              : state.isLoadingFor(overlayMetric),
    );

    final chartKind = isTemperatureOverlayMode
        ? TelemetryHistorySlideChartKind.temperatureOverlay
        : metric.displayMode == TelemetryHistoryMetricDisplayMode.energyDelta ||
                metric.displayMode ==
                    TelemetryHistoryMetricDisplayMode.energyUsage ||
                metric.displayMode ==
                    TelemetryHistoryMetricDisplayMode.heatingUsage
            ? TelemetryHistorySlideChartKind.energyBar
            : metric.kind == TelemetryHistoryMetricKind.numeric
                ? TelemetryHistorySlideChartKind.numericRangeLine
                : TelemetryHistorySlideChartKind.booleanLine;
    final numericSeries =
        chartKind == TelemetryHistorySlideChartKind.numericRangeLine &&
                chartValues.isNotEmpty
            ? <HistoryMultiLineSeries>[
                HistoryMultiLineSeries(
                  id: metric.seriesKey,
                  label: metric.title,
                  points: entries.map(_historyPoint).toList(growable: false),
                  color: _metricColor(metric),
                  strokeWidth: 2.0,
                  fill: true,
                ),
              ]
            : const <HistoryMultiLineSeries>[];
    final hasChartData =
        chartKind == TelemetryHistorySlideChartKind.temperatureOverlay
            ? overlaySeries.isNotEmpty
            : chartValues.isNotEmpty;
    final isEmpty =
        !isLoading && !overlayLoading && errorMessage == null && !hasChartData;
    final chartSemanticLabel = _chartSemanticLabel(
      metric: metric,
      targetLabel: targetMetric?.title ?? s.TelemetryHistoryMetricTarget,
      targetValue: _latestTargetSemanticValue(state, s),
      targetVisible: selectedOverlayIds.contains(targetSeriesId),
    );

    return TelemetryHistorySlideViewModel(
      series: series,
      isLoading: isLoading,
      errorMessage: errorMessage,
      entries: entries,
      summaryItems: summaryItems,
      sensorName: sensorName,
      hasSensorIdentity: hasSensorIdentity,
      overlayOptions: overlayOptions,
      selectedOverlayIds: selectedOverlayIds,
      overlayMetricById: overlayMetricById,
      hasTemperatureAxisSeries: hasTemperatureAxisSeries,
      overlaySeries: overlaySeries,
      overlayLoading: overlayLoading,
      chartValues: chartValues,
      chartRangeMinValues: chartRangeMinValues,
      chartRangeMaxValues: chartRangeMaxValues,
      chartTimestamps: chartTimestamps,
      barChartValues:
          usageBarValues.isEmpty ? chartValues.cast<double?>() : usageBarValues,
      barChartTimestamps:
          usageBarTimestamps.isEmpty ? chartTimestamps : usageBarTimestamps,
      numericSeries: numericSeries,
      chartKind: chartKind,
      isEmpty: isEmpty,
      chartSemanticLabel: chartSemanticLabel,
    );
  }

  static String _chartSemanticLabel({
    required TelemetryHistoryMetric metric,
    required String targetLabel,
    required String? targetValue,
    required bool targetVisible,
  }) {
    if (!targetVisible || targetValue == null || targetValue.isEmpty) {
      return metric.title;
    }
    return '${metric.title}. $targetLabel: $targetValue';
  }

  static String? _latestTargetSemanticValue(
    TelemetryHistoryState state,
    S s,
  ) {
    final points = state.setpointHistory?.points;
    if (points == null || points.isEmpty) return null;
    final setpoint = points.last.state;
    return switch (setpoint.kind) {
      TelemetrySetpointKind.inactive => s.TelemetryHistoryTargetInactive,
      TelemetrySetpointKind.temperature =>
        '${setpoint.temperature!.toStringAsFixed(1)} °C',
      TelemetrySetpointKind.on => 'ON',
      TelemetrySetpointKind.off => 'OFF',
    };
  }

  static bool isTemperatureMetric(TelemetryHistoryMetric metric) {
    return metric.kind == TelemetryHistoryMetricKind.numeric &&
        metric.seriesKey.endsWith('.temp');
  }

  static List<TelemetryHistoryChartEntry> chartEntries(
    TelemetryHistorySeries? series,
    TelemetryHistoryMetric metric,
  ) {
    if (series == null) return const <TelemetryHistoryChartEntry>[];

    final entries = <TelemetryHistoryChartEntry>[];
    for (final point in series.points) {
      double? rangeMinValue;
      double? rangeMaxValue;
      final rawValue = switch (metric.kind) {
        TelemetryHistoryMetricKind.numeric =>
          metric.displayMode == TelemetryHistoryMetricDisplayMode.energyDelta ||
                  metric.displayMode ==
                      TelemetryHistoryMetricDisplayMode.energyUsage
              ? point.sumValue
              : metric.displayMode ==
                      TelemetryHistoryMetricDisplayMode.heatingUsage
                  ? point.lastNumericValue
                  : metric.useSumValue
                      ? point.sumValue ??
                          point.avgValue ??
                          point.lastNumericValue ??
                          point.maxValue ??
                          point.minValue
                      : point.maxValue ??
                          point.avgValue ??
                          point.lastNumericValue ??
                          point.minValue,
        TelemetryHistoryMetricKind.boolean => point.trueRatio ??
            (point.lastBoolValue == null
                ? null
                : (point.lastBoolValue! ? 1.0 : 0.0)),
      };
      if (rawValue == null) continue;

      if (metric.kind == TelemetryHistoryMetricKind.numeric &&
          !metric.useSumValue &&
          point.minValue != null &&
          point.maxValue != null &&
          point.minValue! <= point.maxValue!) {
        rangeMinValue = point.minValue! * metric.valueMultiplier;
        rangeMaxValue = point.maxValue! * metric.valueMultiplier;
      }

      final value = metric.kind == TelemetryHistoryMetricKind.numeric
          ? rawValue * metric.valueMultiplier
          : rawValue;
      entries.add(
        TelemetryHistoryChartEntry(
          timestamp: point.bucketStart,
          value: value,
          rangeMinValue: rangeMinValue,
          rangeMaxValue: rangeMaxValue,
          referenceSensorId: point.referenceSensorId,
        ),
      );
    }
    return entries;
  }

  static List<HistoryMultiLinePoint> _setpointPoints(
    TelemetryHistoryState state,
  ) {
    final history = state.setpointHistory;
    if (history == null) return const <HistoryMultiLinePoint>[];
    return history.points.map((point) {
      final setpoint = point.state;
      return switch (setpoint.kind) {
        TelemetrySetpointKind.inactive => HistoryMultiLinePoint(
            timestamp: point.bucketStart,
            value: null,
          ),
        TelemetrySetpointKind.temperature => HistoryMultiLinePoint(
            timestamp: point.bucketStart,
            value: setpoint.temperature!,
            tooltipText: '${setpoint.temperature!.toStringAsFixed(1)} °C',
          ),
        TelemetrySetpointKind.on => HistoryMultiLinePoint(
            timestamp: point.bucketStart,
            value: _onSetpointChartValue,
            tooltipText: 'ON',
          ),
        TelemetrySetpointKind.off => HistoryMultiLinePoint(
            timestamp: point.bucketStart,
            value: 0,
            axisFraction: _offSetpointAxisFraction,
            includeInYAxisRange: false,
            tooltipText: 'OFF',
          ),
      };
    }).toList(growable: false);
  }

  static TelemetryHistoryMetric? _findComparisonMetric(
    TelemetryHistoryState state,
    String seriesKey,
  ) {
    for (final metric in state.comparisonMetrics) {
      if (metric.seriesKey == seriesKey) {
        return metric;
      }
    }
    return null;
  }

  static Set<String> _selectedTemperatureToggleIds(
    List<TelemetryHistoryOverlayOption> options,
    Set<String> enabledTemperatureSeries,
  ) {
    if (options.isEmpty) {
      return const <String>{};
    }
    final available = options.map((option) => option.id).toSet();
    return enabledTemperatureSeries.intersection(available);
  }

  static List<HistoryMultiLineSeries> _overlaySeries({
    required TelemetryHistoryMetric metric,
    required List<TelemetryHistoryChartEntry> entries,
    required List<TelemetryHistoryOverlayOption> overlayOptions,
    required Set<String> selectedOverlayIds,
    required List<HistoryMultiLinePoint> setpointPoints,
    required List<TelemetryHistoryChartEntry> heatingEntries,
    required bool hasTemperatureAxisSeries,
    DateTime? windowStart,
    DateTime? windowEnd,
  }) {
    final overlaySeries = <HistoryMultiLineSeries>[];
    if (entries.isNotEmpty) {
      final tempLineColor = _temperatureLineColor(entries, metric);
      overlaySeries.add(
        HistoryMultiLineSeries(
          id: temperatureSeriesId,
          label: metric.title,
          points: entries.map(_historyPoint).toList(growable: false),
          color: tempLineColor,
          lineGradient: _temperatureLineGradient(
            entries,
            metric,
            windowStart: windowStart,
            windowEnd: windowEnd,
          ),
          strokeWidth: 2.0,
          fill: true,
          fillTopAlpha: 0.32,
          fillBottomAlpha: 0.07,
        ),
      );
    }

    for (final option in overlayOptions) {
      if (!selectedOverlayIds.contains(option.id)) {
        continue;
      }

      if (option.id == targetSeriesId) {
        if (setpointPoints.isNotEmpty) {
          overlaySeries.add(
            HistoryMultiLineSeries(
              id: targetSeriesId,
              label: option.label,
              points: setpointPoints,
              color: option.color,
              strokeWidth: 2.0,
              fill: true,
              fillTopAlpha: 0.22,
              fillBottomAlpha: 0.04,
              isStepLine: true,
            ),
          );
        }
        continue;
      }

      final sourceEntries = switch (option.id) {
        heatingSeriesId => heatingEntries,
        _ => const <TelemetryHistoryChartEntry>[],
      };
      if (sourceEntries.isEmpty) {
        continue;
      }

      final useActivityBand =
          option.id == heatingSeriesId && hasTemperatureAxisSeries;

      overlaySeries.add(
        HistoryMultiLineSeries(
          id: option.id,
          label: option.label,
          points: sourceEntries
              .map(
                (entry) => _historyPoint(
                  entry,
                  includeRange: !useActivityBand,
                ),
              )
              .toList(growable: false),
          color: option.color,
          strokeWidth: useActivityBand ? 1.6 : 2.0,
          fill: true,
          fillTopAlpha: useActivityBand ? 0.34 : 0.22,
          fillBottomAlpha: useActivityBand ? 0.08 : 0.04,
          includeInYAxisRange: !useActivityBand,
          activityBand:
              useActivityBand ? const HistoryMultiLineActivityBand() : null,
        ),
      );
    }

    return overlaySeries;
  }

  static HistoryMultiLinePoint _historyPoint(
    TelemetryHistoryChartEntry entry, {
    bool includeRange = true,
  }) {
    return HistoryMultiLinePoint(
      timestamp: entry.timestamp,
      value: entry.value,
      displayValue: entry.value,
      rangeMinValue: includeRange ? entry.rangeMinValue : null,
      rangeMaxValue: includeRange ? entry.rangeMaxValue : null,
    );
  }

  static List<TelemetryHistorySummaryItem> _summaryItems(
    List<double> values,
    TelemetryHistoryMetric metric,
    S s, {
    required TelemetryHistorySeries? series,
    required double rangeDays,
  }) {
    final usageSummary = series?.usageSummary;
    if (usageSummary != null &&
        metric.displayMode == TelemetryHistoryMetricDisplayMode.energyUsage) {
      return <TelemetryHistorySummaryItem>[
        TelemetryHistorySummaryItem(
          label: s.TelemetryHistoryStatTotal,
          value: _formatServerValue(usageSummary.total, metric),
        ),
        TelemetryHistorySummaryItem(
          label: s.TelemetryHistoryStatAvg,
          value: _formatServerValue(usageSummary.average, metric),
        ),
        TelemetryHistorySummaryItem(
          label: s.TelemetryHistoryStatPeakInterval,
          value: _formatServerValue(usageSummary.peak, metric),
        ),
      ];
    }
    if (usageSummary != null &&
        metric.displayMode == TelemetryHistoryMetricDisplayMode.heatingUsage) {
      return <TelemetryHistorySummaryItem>[
        TelemetryHistorySummaryItem(
          label: s.TelemetryHistoryStatMin,
          value: _formatServerValue(usageSummary.minimum, metric),
        ),
        TelemetryHistorySummaryItem(
          label: s.TelemetryHistoryStatMax,
          value: _formatServerValue(usageSummary.maximum, metric),
        ),
        TelemetryHistorySummaryItem(
          label: s.TelemetryHistoryStatAvg,
          value: _formatServerValue(usageSummary.average, metric),
        ),
      ];
    }
    final hasValues = values.isNotEmpty;
    if (metric.displayMode == TelemetryHistoryMetricDisplayMode.energyDelta) {
      return _energySummaryItems(
        values,
        metric,
        s,
        rangeDays: rangeDays,
      );
    }

    final avg =
        hasValues ? values.reduce((a, b) => a + b) / values.length : null;
    final avgText = avg == null
        ? '--'
        : TelemetryHistoryMetricValueFormatter.format(avg, metric);

    if (metric.kind == TelemetryHistoryMetricKind.boolean) {
      return <TelemetryHistorySummaryItem>[
        TelemetryHistorySummaryItem(
          label: s.TelemetryHistoryStatAvg,
          value: avgText,
        ),
      ];
    }

    final minValue = hasValues ? values.reduce(math.min) : null;
    final maxValue = hasValues ? values.reduce(math.max) : null;

    return <TelemetryHistorySummaryItem>[
      TelemetryHistorySummaryItem(
        label: s.TelemetryHistoryStatMin,
        value: minValue == null
            ? '--'
            : TelemetryHistoryMetricValueFormatter.format(minValue, metric),
      ),
      TelemetryHistorySummaryItem(
        label: s.TelemetryHistoryStatMax,
        value: maxValue == null
            ? '--'
            : TelemetryHistoryMetricValueFormatter.format(maxValue, metric),
      ),
      TelemetryHistorySummaryItem(
        label: s.TelemetryHistoryStatAvg,
        value: avgText,
      ),
    ];
  }

  static String _formatServerValue(
    double? value,
    TelemetryHistoryMetric metric,
  ) {
    return value == null
        ? '—'
        : TelemetryHistoryMetricValueFormatter.format(value, metric);
  }

  static List<TelemetryHistorySummaryItem> _energySummaryItems(
    List<double> values,
    TelemetryHistoryMetric metric,
    S s, {
    required double rangeDays,
  }) {
    final hasValues = values.isNotEmpty;
    final total = hasValues
        ? values.fold<double>(0.0, (sum, value) => sum + value)
        : null;
    final isSingleCalendarDay = rangeDays <= 1;
    final averageDivisor =
        isSingleCalendarDay ? 24.0 : rangeDays.clamp(1.0, double.infinity);
    final averageLabel = isSingleCalendarDay
        ? s.TelemetryHistoryStatAvgPerHour
        : s.TelemetryHistoryStatAvgPerDay;
    final average = total == null ? null : total / averageDivisor;
    final peakInterval = hasValues ? values.reduce(math.max) : null;

    return <TelemetryHistorySummaryItem>[
      TelemetryHistorySummaryItem(
        label: s.TelemetryHistoryStatTotal,
        value: total == null
            ? '--'
            : TelemetryHistoryMetricValueFormatter.format(total, metric),
      ),
      TelemetryHistorySummaryItem(
        label: averageLabel,
        value: average == null
            ? '--'
            : TelemetryHistoryMetricValueFormatter.format(average, metric),
      ),
      TelemetryHistorySummaryItem(
        label: s.TelemetryHistoryStatPeakInterval,
        value: peakInterval == null
            ? '--'
            : TelemetryHistoryMetricValueFormatter.format(peakInterval, metric),
      ),
    ];
  }

  static Color _metricColor(TelemetryHistoryMetric metric) {
    return switch (metric.seriesKey) {
      TelemetryHistoryMetricCatalog.powerMeterActivePowerW =>
        AppPalette.historyHeating,
      TelemetryHistoryMetricCatalog.powerMeterVoltageV =>
        AppPalette.historyTemperature,
      TelemetryHistoryMetricCatalog.powerMeterCurrentA => AppPalette.cyanAccent,
      TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta =>
        AppPalette.accentSuccess,
      _ => AppPalette.historyTemperature,
    };
  }

  static Color _temperaturePointColor(
    TelemetryHistoryChartEntry entry,
    String sensorId,
  ) {
    final referenceId = entry.referenceSensorId?.trim();
    if (referenceId == null || referenceId.isEmpty) {
      return _tempInactiveColor;
    }
    return referenceId == sensorId
        ? AppPalette.historyTemperature
        : _tempInactiveColor;
  }

  static Color _temperatureLineColor(
    List<TelemetryHistoryChartEntry> entries,
    TelemetryHistoryMetric metric,
  ) {
    final sensorId = metric.sensorId?.trim();
    if (sensorId == null || sensorId.isEmpty || entries.isEmpty) {
      return AppPalette.accentPrimary;
    }

    for (final entry in entries) {
      final referenceId = entry.referenceSensorId?.trim();
      if (referenceId == null || referenceId.isEmpty) {
        continue;
      }
      return _temperaturePointColor(entry, sensorId);
    }
    return AppPalette.accentPrimary;
  }

  static LinearGradient? _temperatureLineGradient(
    List<TelemetryHistoryChartEntry> entries,
    TelemetryHistoryMetric metric, {
    DateTime? windowStart,
    DateTime? windowEnd,
  }) {
    final sensorId = metric.sensorId?.trim();
    if (sensorId == null || sensorId.isEmpty || entries.length < 2) {
      return null;
    }
    final hasReferenceData = entries.any(
      (entry) => (entry.referenceSensorId?.trim().isNotEmpty ?? false),
    );
    if (!hasReferenceData) {
      return null;
    }

    final startUtc = windowStart?.toUtc();
    final endUtc = windowEnd?.toUtc();
    final hasWindow =
        startUtc != null && endUtc != null && endUtc.isAfter(startUtc);
    final spanMicros =
        hasWindow ? endUtc.difference(startUtc).inMicroseconds.toDouble() : 0.0;

    double stopForEntry(int index) {
      if (hasWindow && spanMicros > 0) {
        final offsetMicros = entries[index]
            .timestamp
            .toUtc()
            .difference(startUtc)
            .inMicroseconds
            .toDouble();
        return (offsetMicros / spanMicros).clamp(0.0, 1.0);
      }
      if (entries.length == 1) return 0.0;
      return (index / (entries.length - 1)).clamp(0.0, 1.0);
    }

    final colors = <Color>[];
    final stops = <double>[];
    var previousColor = _temperaturePointColor(entries.first, sensorId);

    colors.add(previousColor);
    stops.add(stopForEntry(0));
    var hasColorTransitions = false;

    for (var i = 1; i < entries.length; i++) {
      final currentColor = _temperaturePointColor(entries[i], sensorId);
      final currentStop = stopForEntry(i);
      if (currentColor != previousColor) {
        hasColorTransitions = true;
        colors.add(previousColor);
        stops.add(currentStop);
      }
      colors.add(currentColor);
      stops.add(currentStop);
      previousColor = currentColor;
    }

    if (stops.first > 0.0) {
      colors.insert(0, colors.first);
      stops.insert(0, 0.0);
    }
    if (stops.last < 1.0) {
      colors.add(colors.last);
      stops.add(1.0);
    }

    if (!hasColorTransitions) {
      return null;
    }

    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: colors,
      stops: stops,
    );
  }
}
