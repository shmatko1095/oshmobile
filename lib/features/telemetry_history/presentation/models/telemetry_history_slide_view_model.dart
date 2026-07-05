import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_chart.dart';
import 'package:oshmobile/generated/l10n.dart';

enum TelemetryHistorySlideChartKind {
  temperatureOverlay,
  energyBar,
  numericRangeLine,
  booleanLine,
}

class TelemetryHistorySlideViewModel {
  const TelemetryHistorySlideViewModel({
    required this.series,
    required this.isLoading,
    required this.errorMessage,
    required this.entries,
    required this.summaryItems,
    required this.sensorName,
    required this.hasSensorIdentity,
    required this.overlayOptions,
    required this.selectedOverlayIds,
    required this.overlayMetricById,
    required this.hasTemperatureAxisSeries,
    required this.overlaySeries,
    required this.overlayLoading,
    required this.chartValues,
    required this.chartRangeMinValues,
    required this.chartRangeMaxValues,
    required this.chartTimestamps,
    required this.numericSeries,
    required this.chartKind,
    required this.isEmpty,
  });

  final TelemetryHistorySeries? series;
  final bool isLoading;
  final String? errorMessage;
  final List<TelemetryHistoryChartEntry> entries;
  final List<TelemetryHistorySummaryItem> summaryItems;
  final String sensorName;
  final bool hasSensorIdentity;
  final List<TelemetryHistoryOverlayOption> overlayOptions;
  final Set<String> selectedOverlayIds;
  final Map<String, TelemetryHistoryMetric> overlayMetricById;
  final bool hasTemperatureAxisSeries;
  final List<HistoryMultiLineSeries> overlaySeries;
  final bool overlayLoading;
  final List<double> chartValues;
  final List<double?> chartRangeMinValues;
  final List<double?> chartRangeMaxValues;
  final List<DateTime> chartTimestamps;
  final List<HistoryMultiLineSeries> numericSeries;
  final TelemetryHistorySlideChartKind chartKind;
  final bool isEmpty;
}

class TelemetryHistorySlideModelBuilder {
  const TelemetryHistorySlideModelBuilder._();

  static const String temperatureSeriesId = 'temp';
  static const String targetSeriesId = 'target';
  static const String heatingSeriesId = 'heating';
  static const Color _tempInactiveColor = AppPalette.chartTempInactive;

  static TelemetryHistorySlideViewModel build({
    required TelemetryHistoryState state,
    required TelemetryHistoryMetric metric,
    required Set<String> enabledTemperatureSeries,
    required S s,
  }) {
    final isTemperatureOverlayMode =
        isTemperatureMetric(metric) && state.hasComparisonMetrics;
    final targetMetric = _findComparisonMetric(state, 'target_temp');
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
                color: AppPalette.accentSuccess,
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
    final summaryItems = _summaryItems(
      chartValues,
      metric,
      s,
      range: state.range,
    );
    final sensorName = (metric.subtitle ?? '').trim();
    final hasSensorIdentity = sensorName.isNotEmpty && metric.sensorId != null;

    final targetEntries = targetMetric == null
        ? const <TelemetryHistoryChartEntry>[]
        : chartEntries(state.seriesFor(targetMetric), targetMetric);
    final heatingEntries = heatingMetric == null
        ? const <TelemetryHistoryChartEntry>[]
        : chartEntries(state.seriesFor(heatingMetric), heatingMetric);

    final hasTemperatureAxisSeries = entries.isNotEmpty ||
        (selectedOverlayIds.contains(targetSeriesId) &&
            targetEntries.isNotEmpty);
    final overlaySeries = _overlaySeries(
      metric: metric,
      entries: entries,
      overlayOptions: overlayOptions,
      selectedOverlayIds: selectedOverlayIds,
      targetEntries: targetEntries,
      heatingEntries: heatingEntries,
      hasTemperatureAxisSeries: hasTemperatureAxisSeries,
      windowStart: series?.from,
      windowEnd: series?.to,
    );
    final selectedOverlayMetrics = overlayOptions
        .where((option) => selectedOverlayIds.contains(option.id))
        .map((option) => option.metric)
        .toList(growable: false);
    final overlayLoading = selectedOverlayMetrics
        .any((overlayMetric) => state.isLoadingFor(overlayMetric));

    final chartKind = isTemperatureOverlayMode
        ? TelemetryHistorySlideChartKind.temperatureOverlay
        : metric.displayMode == TelemetryHistoryMetricDisplayMode.energyDelta
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
                  values: chartValues,
                  displayValues: chartValues,
                  timestamps: chartTimestamps,
                  rangeMinValues: chartRangeMinValues,
                  rangeMaxValues: chartRangeMaxValues,
                  color: AppPalette.accentPrimary,
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
      numericSeries: numericSeries,
      chartKind: chartKind,
      isEmpty: isEmpty,
    );
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
          metric.displayMode == TelemetryHistoryMetricDisplayMode.energyDelta
              ? point.sumValue
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
    required List<TelemetryHistoryChartEntry> targetEntries,
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
          values: entries.map((entry) => entry.value).toList(growable: false),
          displayValues:
              entries.map((entry) => entry.value).toList(growable: false),
          timestamps:
              entries.map((entry) => entry.timestamp).toList(growable: false),
          rangeMinValues: entries
              .map((entry) => entry.rangeMinValue)
              .toList(growable: false),
          rangeMaxValues: entries
              .map((entry) => entry.rangeMaxValue)
              .toList(growable: false),
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

      final sourceEntries = switch (option.id) {
        targetSeriesId => targetEntries,
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
          values:
              sourceEntries.map((entry) => entry.value).toList(growable: false),
          displayValues:
              sourceEntries.map((entry) => entry.value).toList(growable: false),
          timestamps: sourceEntries
              .map((entry) => entry.timestamp)
              .toList(growable: false),
          rangeMinValues: useActivityBand
              ? null
              : sourceEntries
                  .map((entry) => entry.rangeMinValue)
                  .toList(growable: false),
          rangeMaxValues: useActivityBand
              ? null
              : sourceEntries
                  .map((entry) => entry.rangeMaxValue)
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

  static List<TelemetryHistorySummaryItem> _summaryItems(
    List<double> values,
    TelemetryHistoryMetric metric,
    S s, {
    required TelemetryHistoryRange range,
  }) {
    final hasValues = values.isNotEmpty;
    if (metric.displayMode == TelemetryHistoryMetricDisplayMode.energyDelta) {
      return _energySummaryItems(
        values,
        metric,
        s,
        range: range,
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

  static List<TelemetryHistorySummaryItem> _energySummaryItems(
    List<double> values,
    TelemetryHistoryMetric metric,
    S s, {
    required TelemetryHistoryRange range,
  }) {
    final hasValues = values.isNotEmpty;
    final total = hasValues
        ? values.fold<double>(0.0, (sum, value) => sum + value)
        : null;
    final averageDivisor =
        range == TelemetryHistoryRange.day ? 24.0 : _rangeDays(range);
    final averageLabel = range == TelemetryHistoryRange.day
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

  static double _rangeDays(TelemetryHistoryRange range) {
    return switch (range) {
      TelemetryHistoryRange.day => 1,
      TelemetryHistoryRange.week => 7,
      TelemetryHistoryRange.month => 30,
      TelemetryHistoryRange.year => 365,
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
        ? AppPalette.accentPrimary
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

class TelemetryHistoryMetricValueFormatter {
  const TelemetryHistoryMetricValueFormatter._();

  static String format(double value, TelemetryHistoryMetric metric) {
    if (metric.kind == TelemetryHistoryMetricKind.boolean) {
      return '${(value * 100).round()}%';
    }
    final unit = metric.unit.isEmpty ? '' : ' ${metric.unit}';
    return '${value.toStringAsFixed(metric.fractionDigits)}$unit';
  }
}

class TelemetryHistorySummaryItem {
  const TelemetryHistorySummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class TelemetryHistoryOverlayOption {
  const TelemetryHistoryOverlayOption({
    required this.id,
    required this.label,
    required this.metric,
    required this.color,
  });

  final String id;
  final String label;
  final TelemetryHistoryMetric metric;
  final Color color;
}

class TelemetryHistoryChartEntry {
  const TelemetryHistoryChartEntry({
    required this.timestamp,
    required this.value,
    this.rangeMinValue,
    this.rangeMaxValue,
    this.referenceSensorId,
  });

  final DateTime timestamp;
  final double value;
  final double? rangeMinValue;
  final double? rangeMaxValue;
  final String? referenceSensorId;
}
