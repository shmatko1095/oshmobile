part of 'telemetry_history_page.dart';

class _MetricSlide extends StatelessWidget {
  const _MetricSlide({
    required this.state,
    required this.metric,
    required this.metricIndex,
    required this.localeTag,
    required this.s,
    required this.enabledTemperatureSeries,
    required this.onToggleTemperatureSeries,
  });

  final TelemetryHistoryState state;
  final TelemetryHistoryMetric metric;
  final int metricIndex;
  final String localeTag;
  final S s;
  final Set<String> enabledTemperatureSeries;
  final ValueChanged<String> onToggleTemperatureSeries;

  @override
  Widget build(BuildContext context) {
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
    final selectedOverlayIds =
        _selectedTemperatureToggleIds(overlayOptions, enabledTemperatureSeries);
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
                                            onToggle: onToggleTemperatureSeries,
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
}
