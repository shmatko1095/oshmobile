import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_line_chart.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_chart.dart';
import 'package:oshmobile/generated/l10n.dart';

bool _historyIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _historySurfaceColor(BuildContext context) =>
    _historyIsDark(context) ? AppPalette.surfaceRaised : Colors.white;

Color _historySurfaceAltColor(BuildContext context) =>
    _historyIsDark(context) ? AppPalette.surfaceAlt : const Color(0xFFF3F4F6);

Color _historyBorderColor(BuildContext context) =>
    _historyIsDark(context) ? AppPalette.borderSoft : const Color(0x1A0F172A);

Color _historyPrimaryTextColor(BuildContext context) =>
    _historyIsDark(context) ? AppPalette.textPrimary : const Color(0xFF0F172A);

Color _historySecondaryTextColor(BuildContext context) =>
    _historyIsDark(context)
        ? AppPalette.textSecondary
        : const Color(0xFF475569);

Color _historyMutedTextColor(BuildContext context) =>
    _historyIsDark(context) ? AppPalette.textMuted : const Color(0xFF64748B);

class TelemetryHistoryPage extends StatefulWidget {
  const TelemetryHistoryPage({
    super.key,
  });

  @override
  State<TelemetryHistoryPage> createState() => _TelemetryHistoryPageState();
}

class _TelemetryHistoryPageState extends State<TelemetryHistoryPage> {
  static const List<TelemetryHistoryRange> _visibleRanges =
      <TelemetryHistoryRange>[
    TelemetryHistoryRange.day,
    TelemetryHistoryRange.week,
    TelemetryHistoryRange.month,
    TelemetryHistoryRange.year,
  ];
  static const String _toggleTemp = 'temp';
  static const String _toggleTarget = 'target';
  static const String _toggleHeating = 'heating';
  static const Color _tempInactiveColor = Color(0xFF7BC5FF);

  late final PageController _pageController;
  Set<String> _enabledTemperatureSeries = <String>{};
  String? _comparisonLoadKey;

  @override
  void initState() {
    super.initState();
    final initialPage =
        context.read<TelemetryHistoryCubit>().state.selectedMetricIndex;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isTemperatureMetric(TelemetryHistoryMetric metric) {
    return metric.kind == TelemetryHistoryMetricKind.numeric &&
        metric.seriesKey.endsWith('.temp');
  }

  TelemetryHistoryMetric? _findComparisonMetric(
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

  void _ensureComparisonLoaded(
    BuildContext context,
    TelemetryHistoryState state,
    TelemetryHistoryMetric metric,
  ) {
    if (!_isTemperatureMetric(metric) || !state.hasComparisonMetrics) {
      return;
    }
    final loadKey = '${state.range.name}|${metric.seriesKey}';
    if (_comparisonLoadKey == loadKey) {
      return;
    }
    _comparisonLoadKey = loadKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<TelemetryHistoryCubit>()
          .ensureMetricsLoaded(state.comparisonMetrics);
    });
  }

  Set<String> _selectedTemperatureToggles(List<_OverlayToggleOption> options) {
    if (options.isEmpty) {
      return const <String>{};
    }
    final available = options.map((option) => option.id).toSet();
    return _enabledTemperatureSeries.intersection(available);
  }

  void _toggleTemperatureSeries(String id) {
    setState(() {
      final next = <String>{..._enabledTemperatureSeries};
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      _enabledTemperatureSeries = next;
    });
  }

  List<_ChartEntry> _chartEntries(
    TelemetryHistorySeries? series,
    TelemetryHistoryMetric metric,
  ) {
    if (series == null) return const <_ChartEntry>[];

    final entries = <_ChartEntry>[];
    for (final point in series.points) {
      final value = switch (metric.kind) {
        TelemetryHistoryMetricKind.numeric => point.avgValue ??
            point.lastNumericValue ??
            point.maxValue ??
            point.minValue,
        TelemetryHistoryMetricKind.boolean => point.trueRatio ??
            (point.lastBoolValue == null
                ? null
                : (point.lastBoolValue! ? 1.0 : 0.0)),
      };
      if (value == null) continue;
      entries.add(
        _ChartEntry(
          timestamp: point.bucketStart,
          value: value,
          referenceSensorId: point.referenceSensorId,
        ),
      );
    }
    return entries;
  }

  String _fmtValue(double value, TelemetryHistoryMetric metric) {
    if (metric.kind == TelemetryHistoryMetricKind.boolean) {
      return '${(value * 100).round()}%';
    }
    final unit = metric.unit.isEmpty ? '' : ' ${metric.unit}';
    return '${value.toStringAsFixed(1)}$unit';
  }

  String _rangeLabel(S s, TelemetryHistoryRange range) {
    return switch (range) {
      TelemetryHistoryRange.day => s.TelemetryHistoryRangeDay,
      TelemetryHistoryRange.week => s.TelemetryHistoryRangeWeek,
      TelemetryHistoryRange.month => s.TelemetryHistoryRangeMonth,
      TelemetryHistoryRange.year => s.TelemetryHistoryRangeYear,
    };
  }

  String _xAxisLabel({
    required DateTime timestamp,
    required TelemetryHistoryRange range,
    required String localeTag,
  }) {
    final local = timestamp.toLocal();
    return switch (range) {
      TelemetryHistoryRange.day =>
        DateFormat('MM/dd HH:mm', localeTag).format(local),
      TelemetryHistoryRange.week =>
        DateFormat('MM/dd', localeTag).format(local),
      TelemetryHistoryRange.month =>
        DateFormat('MM/dd', localeTag).format(local),
      TelemetryHistoryRange.year =>
        DateFormat('MM/yy', localeTag).format(local),
    };
  }

  String _tooltipLabel({
    required DateTime timestamp,
    required double value,
    required TelemetryHistoryMetric metric,
    required String localeTag,
  }) {
    final local = timestamp.toLocal();
    final time = DateFormat('MM/dd HH:mm', localeTag).format(local);
    return '$time\n${_fmtValue(value, metric)}';
  }

  String _tooltipTimeLabel({
    required DateTime timestamp,
    required String localeTag,
  }) {
    return DateFormat('MM/dd HH:mm', localeTag).format(timestamp.toLocal());
  }

  List<_SummaryItem> _summaryItems(
    List<double> values,
    TelemetryHistoryMetric metric,
    S s,
  ) {
    final hasValues = values.isNotEmpty;
    final avg =
        hasValues ? values.reduce((a, b) => a + b) / values.length : null;
    final avgText = avg == null ? '--' : _fmtValue(avg, metric);

    if (metric.kind == TelemetryHistoryMetricKind.boolean) {
      return <_SummaryItem>[
        _SummaryItem(
          label: s.TelemetryHistoryStatAvg,
          value: avgText,
        ),
      ];
    }

    final minValue = hasValues ? values.reduce(math.min) : null;
    final maxValue = hasValues ? values.reduce(math.max) : null;

    return <_SummaryItem>[
      _SummaryItem(
        label: s.TelemetryHistoryStatMin,
        value: minValue == null ? '--' : _fmtValue(minValue, metric),
      ),
      _SummaryItem(
        label: s.TelemetryHistoryStatMax,
        value: maxValue == null ? '--' : _fmtValue(maxValue, metric),
      ),
      _SummaryItem(
        label: s.TelemetryHistoryStatAvg,
        value: avgText,
      ),
    ];
  }

  _NumericDomain _resolveNumericDomain(
    List<_ChartEntry> primaryEntries,
    List<_ChartEntry> targetEntries,
  ) {
    final values = <double>[
      ...primaryEntries.map((entry) => entry.value),
      ...targetEntries.map((entry) => entry.value),
    ];
    if (values.isEmpty) {
      return const _NumericDomain(min: 0, max: 1);
    }

    final minRaw = values.reduce(math.min);
    final maxRaw = values.reduce(math.max);
    final span = (maxRaw - minRaw).abs();
    if (span > 0.0001) {
      return _NumericDomain(min: minRaw, max: maxRaw);
    }

    final fallbackPadding = math.max(minRaw.abs() * 0.04, 1.0);
    return _NumericDomain(
      min: minRaw - fallbackPadding,
      max: maxRaw + fallbackPadding,
    );
  }

  List<_ChartEntry> _mapBooleanToTemperatureDomain(
    List<_ChartEntry> entries, {
    required _NumericDomain domain,
  }) {
    if (entries.isEmpty) {
      return const <_ChartEntry>[];
    }
    final span = math.max((domain.max - domain.min).abs(), 2.0);
    final lower = domain.min + span * 0.08;
    final upper = domain.max - span * 0.08;
    final cappedUpper = upper <= lower ? lower + 1.0 : upper;

    return entries
        .map(
          (entry) => _ChartEntry(
            timestamp: entry.timestamp,
            value: lower + entry.value.clamp(0.0, 1.0) * (cappedUpper - lower),
            referenceSensorId: entry.referenceSensorId,
          ),
        )
        .toList(growable: false);
  }

  Color _temperaturePointColor(_ChartEntry entry, String sensorId) {
    final referenceId = entry.referenceSensorId?.trim();
    if (referenceId == null || referenceId.isEmpty) {
      return _tempInactiveColor;
    }
    return referenceId == sensorId
        ? AppPalette.accentPrimary
        : _tempInactiveColor;
  }

  Color _temperatureLineColor(
    List<_ChartEntry> entries,
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

  LinearGradient? _temperatureLineGradient(
    List<_ChartEntry> entries,
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
    var previousStop = stopForEntry(0);

    colors.add(previousColor);
    stops.add(previousStop);
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
      previousStop = currentStop;
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

  void _syncPager(TelemetryHistoryState state) {
    if (!_pageController.hasClients) return;
    final page = _pageController.page?.round();
    if (page == state.selectedMetricIndex) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final current = _pageController.page?.round();
      if (current == state.selectedMetricIndex) return;
      _pageController.jumpToPage(state.selectedMetricIndex);
    });
  }

  Widget _buildMetricSlide(
    BuildContext context, {
    required TelemetryHistoryState state,
    required TelemetryHistoryMetric metric,
    required int metricIndex,
    required String localeTag,
    required S s,
  }) {
    _ensureComparisonLoaded(context, state, metric);

    final isTemperatureOverlayMode =
        _isTemperatureMetric(metric) && state.hasComparisonMetrics;
    final targetMetric = _findComparisonMetric(state, 'target_temp');
    final heatingMetric = _findComparisonMetric(state, 'heater_enabled');
    final overlayOptions = isTemperatureOverlayMode
        ? <_OverlayToggleOption>[
            if (heatingMetric != null)
              _OverlayToggleOption(
                id: _toggleHeating,
                label: heatingMetric.title,
                metric: heatingMetric,
                color: AppPalette.accentWarning,
              ),
            if (targetMetric != null)
              _OverlayToggleOption(
                id: _toggleTarget,
                label: targetMetric.title,
                metric: targetMetric,
                color: AppPalette.accentSuccess,
              ),
          ]
        : const <_OverlayToggleOption>[];
    final selectedOverlayIds = _selectedTemperatureToggles(overlayOptions);
    final overlayMetricById = {
      _toggleTemp: metric,
      for (final option in overlayOptions) option.id: option.metric,
    };

    final series = state.seriesFor(metric);
    final isLoading = state.isLoadingFor(metric);
    final errorMessage = state.errorFor(metric);
    final entries = _chartEntries(series, metric);
    final values = entries.map((entry) => entry.value).toList(growable: false);
    final summaryItems = _summaryItems(values, metric, s);
    final sensorName = (metric.subtitle ?? '').trim();
    final hasSensorIdentity = sensorName.isNotEmpty && metric.sensorId != null;

    final targetEntries = targetMetric == null
        ? const <_ChartEntry>[]
        : _chartEntries(state.seriesFor(targetMetric), targetMetric);
    final heatingEntries = heatingMetric == null
        ? const <_ChartEntry>[]
        : _chartEntries(state.seriesFor(heatingMetric), heatingMetric);
    final temperatureDomain = _resolveNumericDomain(entries, targetEntries);

    final hasTemperatureAxisSeries = entries.isNotEmpty ||
        (selectedOverlayIds.contains(_toggleTarget) &&
            targetEntries.isNotEmpty);

    final overlaySeries = <HistoryMultiLineSeries>[];
    if (isTemperatureOverlayMode) {
      if (entries.isNotEmpty) {
        final tempLineColor = _temperatureLineColor(entries, metric);
        overlaySeries.add(
          HistoryMultiLineSeries(
            id: _toggleTemp,
            label: metric.title,
            values: entries.map((entry) => entry.value).toList(growable: false),
            displayValues:
                entries.map((entry) => entry.value).toList(growable: false),
            timestamps:
                entries.map((entry) => entry.timestamp).toList(growable: false),
            color: tempLineColor,
            lineGradient: _temperatureLineGradient(
              entries,
              metric,
              windowStart: series?.from,
              windowEnd: series?.to,
            ),
            strokeWidth: 2.0,
            fill: true,
          ),
        );
      }
      for (final option in overlayOptions) {
        if (!selectedOverlayIds.contains(option.id)) {
          continue;
        }

        final sourceEntries = switch (option.id) {
          _toggleTarget => targetEntries,
          _toggleHeating => heatingEntries,
          _ => const <_ChartEntry>[],
        };
        if (sourceEntries.isEmpty) {
          continue;
        }

        final resolvedEntries =
            option.id == _toggleHeating && hasTemperatureAxisSeries
                ? _mapBooleanToTemperatureDomain(
                    sourceEntries,
                    domain: temperatureDomain,
                  )
                : sourceEntries;

        overlaySeries.add(
          HistoryMultiLineSeries(
            id: option.id,
            label: option.label,
            values: resolvedEntries
                .map((entry) => entry.value)
                .toList(growable: false),
            displayValues: sourceEntries
                .map((entry) => entry.value)
                .toList(growable: false),
            timestamps: resolvedEntries
                .map((entry) => entry.timestamp)
                .toList(growable: false),
            color: option.color,
            strokeWidth: 2.0,
            fill: true,
          ),
        );
      }
    }

    final selectedOverlayMetrics = overlayOptions
        .where((option) => selectedOverlayIds.contains(option.id))
        .map((option) => option.metric)
        .toList(growable: false);
    final overlayLoading = selectedOverlayMetrics
        .any((overlayMetric) => state.isLoadingFor(overlayMetric));

    final lineChartValues = entries.map((entry) => entry.value).toList(
          growable: false,
        );
    final lineChartTimestamps = entries.map((entry) => entry.timestamp).toList(
          growable: false,
        );
    final hasChartData = isTemperatureOverlayMode
        ? overlaySeries.isNotEmpty
        : lineChartValues.isNotEmpty;
    final isEmpty =
        !isLoading && !overlayLoading && errorMessage == null && !hasChartData;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          if (hasSensorIdentity) ...[
            _SensorIdentityBar(
              label: s.TelemetryHistorySensorLabel,
              sensorName: sensorName,
              isPrimary: metric.isPrimarySensor,
              mainLabel: s.SensorMainLabel,
              positionText: state.hasMultipleMetrics
                  ? s.TelemetryHistorySensorPosition(
                      metricIndex + 1,
                      state.metrics.length,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
          ],
          _SummaryPanel(items: summaryItems),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : (errorMessage != null)
                      ? _ErrorState(
                          title: s.TelemetryHistoryLoadFailed,
                          message: errorMessage,
                          retryLabel: s.Retry,
                          onRetry: () => context
                              .read<TelemetryHistoryCubit>()
                              .reloadMetric(metric),
                        )
                      : isEmpty
                          ? _EmptyState(
                              title: s.TelemetryHistoryNoData,
                            )
                          : isTemperatureOverlayMode
                              ? Column(
                                  children: [
                                    if (overlayOptions.isNotEmpty)
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: _OverlaySeriesSelector(
                                            options: overlayOptions,
                                            selectedIds: selectedOverlayIds,
                                            onToggle: _toggleTemperatureSeries,
                                          ),
                                        ),
                                      ),
                                    if (overlayOptions.isNotEmpty)
                                      const SizedBox(height: 8),
                                    Expanded(
                                      child: HistoryMultiLineChart(
                                        series: overlaySeries,
                                        windowStart: series?.from,
                                        windowEnd: series?.to,
                                        showGrid: false,
                                        showAxes: true,
                                        enableTouchTooltip: true,
                                        valueLabelBuilder:
                                            hasTemperatureAxisSeries
                                                ? (v) => _fmtValue(v, metric)
                                                : (v) =>
                                                    '${(v * 100).round()}%',
                                        tooltipValueFormatter:
                                            (seriesId, value) {
                                          final sourceMetric =
                                              overlayMetricById[seriesId];
                                          if (sourceMetric == null) {
                                            return value.toStringAsFixed(2);
                                          }
                                          return _fmtValue(value, sourceMetric);
                                        },
                                        xAxisLabelBuilder: (ts) => _xAxisLabel(
                                          timestamp: ts,
                                          range: state.range,
                                          localeTag: localeTag,
                                        ),
                                        tooltipTimeLabelBuilder: (ts) =>
                                            _tooltipTimeLabel(
                                          timestamp: ts,
                                          localeTag: localeTag,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : HistoryLineChart(
                                  values: lineChartValues,
                                  timestamps: lineChartTimestamps,
                                  windowStart: series?.from,
                                  windowEnd: series?.to,
                                  color: metric.kind ==
                                          TelemetryHistoryMetricKind.boolean
                                      ? AppPalette.accentWarning
                                      : AppPalette.accentPrimary,
                                  strokeWidth: 2.0,
                                  fill: true,
                                  showGrid: false,
                                  showAxes: true,
                                  enableTouchTooltip: true,
                                  valueLabelBuilder: (v) =>
                                      _fmtValue(v, metric),
                                  xAxisLabelBuilder: (ts) => _xAxisLabel(
                                    timestamp: ts,
                                    range: state.range,
                                    localeTag: localeTag,
                                  ),
                                  tooltipBuilder: (ts, value) => _tooltipLabel(
                                    timestamp: ts,
                                    value: value,
                                    metric: metric,
                                    localeTag: localeTag,
                                  ),
                                ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return BlocBuilder<TelemetryHistoryCubit, TelemetryHistoryState>(
      builder: (context, state) {
        _syncPager(state);
        final rangeOptions = _visibleRanges
            .map(
              (range) => _RangeOption(
                range: range,
                label: _rangeLabel(s, range),
              ),
            )
            .toList(growable: false);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(state.metric.title),
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: state.metrics.length,
                  onPageChanged: (index) {
                    context
                        .read<TelemetryHistoryCubit>()
                        .selectMetricIndex(index);
                  },
                  itemBuilder: (context, index) => _buildMetricSlide(
                    context,
                    state: state,
                    metric: state.metrics[index],
                    metricIndex: index,
                    localeTag: localeTag,
                    s: s,
                  ),
                ),
              ),
              SafeArea(
                top: false,
                minimum: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  state.hasMultipleMetrics ? 4 : 10,
                ),
                child: _RangeSelector(
                  options: rangeOptions,
                  selectedRange: state.range,
                  onSelected: (range) {
                    if (range == state.range) return;
                    context.read<TelemetryHistoryCubit>().selectRange(range);
                  },
                ),
              ),
              if (state.hasMultipleMetrics)
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: _PagerDots(
                    count: state.metrics.length,
                    active: state.selectedMetricIndex,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SensorIdentityBar extends StatelessWidget {
  const _SensorIdentityBar({
    required this.label,
    required this.sensorName,
    required this.isPrimary,
    required this.mainLabel,
    required this.positionText,
  });

  final String label;
  final String sensorName;
  final bool isPrimary;
  final String mainLabel;
  final String? positionText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _historySurfaceColor(context),
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        border: Border.all(color: _historyBorderColor(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.accentPrimary.withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              size: 16,
              color: AppPalette.accentPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _historyMutedTextColor(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: AppPalette.motionFast,
                  child: Text(
                    sensorName,
                    key: ValueKey(sensorName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _historyPrimaryTextColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPrimary) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.accentPrimary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
              ),
              child: Text(
                mainLabel,
                style: TextStyle(
                  color: _historyPrimaryTextColor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (positionText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _historySurfaceAltColor(context),
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
                border: Border.all(color: _historyBorderColor(context)),
              ),
              child: Text(
                positionText!,
                style: TextStyle(
                  color: _historySecondaryTextColor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.items,
  });

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _SummaryCell(item: items[i])),
            if (i < items.length - 1)
              Container(
                width: 1,
                height: 44,
                color: _historyBorderColor(context).withValues(alpha: 0.9),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.item,
  });

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          style: TextStyle(
            color: _historySecondaryTextColor(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _historyPrimaryTextColor(context),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _OverlaySeriesSelector extends StatelessWidget {
  const _OverlaySeriesSelector({
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<_OverlayToggleOption> options;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          _OverlaySeriesChip(
            option: options[i],
            selected: selectedIds.contains(options[i].id),
            onTap: () => onToggle(options[i].id),
          ),
          if (i < options.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _OverlaySeriesChip extends StatelessWidget {
  const _OverlaySeriesChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _OverlayToggleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppPalette.motionBase,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? option.color.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            border: Border.all(
              color: selected
                  ? option.color.withValues(alpha: 0.72)
                  : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? option.color
                      : option.color.withValues(alpha: 0.42),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? _historyPrimaryTextColor(context)
                      : _historyMutedTextColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.options,
    required this.selectedRange,
    required this.onSelected,
  });

  final List<_RangeOption> options;
  final TelemetryHistoryRange selectedRange;
  final ValueChanged<TelemetryHistoryRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _historySurfaceColor(context),
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        border: Border.all(color: _historyBorderColor(context)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _RangeChip(
                label: option.label,
                selected: selectedRange == option.range,
                onTap: () => onSelected(option.range),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppPalette.motionBase,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.accentPrimary.withValues(
                    alpha: _historyIsDark(context) ? 0.36 : 0.14,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppPalette.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? _historyPrimaryTextColor(context)
                  : _historyMutedTextColor(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PagerDots extends StatelessWidget {
  const _PagerDots({
    required this.count,
    required this.active,
  });

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppPalette.motionFast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: i == active ? 16 : 6,
            decoration: BoxDecoration(
              color: i == active
                  ? AppPalette.accentPrimary
                  : _historyMutedTextColor(context).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            ),
          ),
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _RangeOption {
  const _RangeOption({
    required this.range,
    required this.label,
  });

  final TelemetryHistoryRange range;
  final String label;
}

class _OverlayToggleOption {
  const _OverlayToggleOption({
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

class _NumericDomain {
  const _NumericDomain({
    required this.min,
    required this.max,
  });

  final double min;
  final double max;
}

class _ChartEntry {
  const _ChartEntry({
    required this.timestamp,
    required this.value,
    this.referenceSensorId,
  });

  final DateTime timestamp;
  final double value;
  final String? referenceSensorId;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _historyPrimaryTextColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _historyMutedTextColor(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onRetry(),
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stacked_line_chart_rounded,
            size: 92,
            color: _historyMutedTextColor(context).withValues(alpha: 0.46),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: _historyMutedTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
