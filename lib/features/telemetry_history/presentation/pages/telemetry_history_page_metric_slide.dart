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
    final model = TelemetryHistorySlideModelBuilder.build(
      state: state,
      metric: metric,
      enabledTemperatureSeries: enabledTemperatureSeries,
      s: s,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          _SummaryPanel(items: model.summaryItems),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
              child: model.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : (model.errorMessage != null)
                      ? _ErrorState(
                          title: s.TelemetryHistoryLoadFailed,
                          message: model.errorMessage!,
                          retryLabel: s.Retry,
                          onRetry: () => context
                              .read<TelemetryHistoryCubit>()
                              .reloadMetric(metric),
                        )
                      : model.isEmpty
                          ? _EmptyState(
                              title: s.TelemetryHistoryNoData,
                            )
                          : model.chartKind ==
                                  TelemetryHistorySlideChartKind
                                      .temperatureOverlay
                              ? Column(
                                  children: [
                                    if (model.overlayOptions.isNotEmpty)
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 6),
                                          child: _OverlaySeriesSelector(
                                            options: model.overlayOptions,
                                            selectedIds:
                                                model.selectedOverlayIds,
                                            onToggle: onToggleTemperatureSeries,
                                          ),
                                        ),
                                      ),
                                    if (model.overlayOptions.isNotEmpty)
                                      const SizedBox(height: 8),
                                    Expanded(
                                      child: HistoryMultiLineChart(
                                        series: model.overlaySeries,
                                        windowStart: model.series?.from,
                                        windowEnd: model.series?.to,
                                        showGrid: false,
                                        showAxes: true,
                                        enableTouchTooltip: true,
                                        valueLabelBuilder: model
                                                .hasTemperatureAxisSeries
                                            ? (v) => _fmtValue(v, metric)
                                            : (v) => '${(v * 100).round()}%',
                                        tooltipValueFormatter:
                                            (seriesId, value) {
                                          final sourceMetric =
                                              model.overlayMetricById[seriesId];
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
                                        tooltipAnchorSeriesId:
                                            TelemetryHistorySlideModelBuilder
                                                .temperatureSeriesId,
                                        semanticLabel: model.chartSemanticLabel,
                                      ),
                                    ),
                                  ],
                                )
                              : model.chartKind ==
                                      TelemetryHistorySlideChartKind.energyBar
                                  ? HistoryBarChart(
                                      values: model.chartValues,
                                      timestamps: model.chartTimestamps,
                                      windowStart: model.series?.from,
                                      windowEnd: model.series?.to,
                                      color: AppPalette.accentSuccess,
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
                                      tooltipTimeLabelBuilder: (ts) =>
                                          _tooltipTimeLabel(
                                        timestamp: ts,
                                        localeTag: localeTag,
                                      ),
                                      semanticLabel: metric.title,
                                    )
                                  : model.chartKind ==
                                          TelemetryHistorySlideChartKind
                                              .numericRangeLine
                                      ? HistoryMultiLineChart(
                                          series: model.numericSeries,
                                          windowStart: model.series?.from,
                                          windowEnd: model.series?.to,
                                          showGrid: false,
                                          showAxes: true,
                                          enableTouchTooltip: true,
                                          valueLabelBuilder: (v) =>
                                              _fmtValue(v, metric),
                                          tooltipValueFormatter: (_, value) =>
                                              _fmtValue(value, metric),
                                          tooltipMinValueFormatter:
                                              (_, value) =>
                                                  _tooltipMinValueLabel(
                                            value: value,
                                            metric: metric,
                                            s: s,
                                          ),
                                          xAxisLabelBuilder: (ts) =>
                                              _xAxisLabel(
                                            timestamp: ts,
                                            range: state.range,
                                            localeTag: localeTag,
                                          ),
                                          tooltipTimeLabelBuilder: (ts) =>
                                              _tooltipTimeLabel(
                                            timestamp: ts,
                                            localeTag: localeTag,
                                          ),
                                        )
                                      : HistoryLineChart(
                                          values: model.chartValues,
                                          timestamps: model.chartTimestamps,
                                          windowStart: model.series?.from,
                                          windowEnd: model.series?.to,
                                          color: AppPalette.accentWarning,
                                          strokeWidth: 2.0,
                                          fill: true,
                                          showGrid: false,
                                          showAxes: true,
                                          enableTouchTooltip: true,
                                          valueLabelBuilder: (v) =>
                                              _fmtValue(v, metric),
                                          xAxisLabelBuilder: (ts) =>
                                              _xAxisLabel(
                                            timestamp: ts,
                                            range: state.range,
                                            localeTag: localeTag,
                                          ),
                                          tooltipBuilder: (ts, value) =>
                                              _tooltipLabel(
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
