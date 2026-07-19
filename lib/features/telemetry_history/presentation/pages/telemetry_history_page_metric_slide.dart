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
      padding: const EdgeInsets.all(AppPalette.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                metric.sensorId == null
                    ? Icons.show_chart_rounded
                    : Icons.device_thermostat_rounded,
                size: 20,
                color: metric.sensorId == null
                    ? AppPalette.historyHeating
                    : AppPalette.historyTemperature,
              ),
              const SizedBox(width: AppPalette.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _historyPrimaryTextColor(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((metric.subtitle ?? '').trim().isNotEmpty)
                      Text(
                        metric.subtitle!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _historyMutedTextColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppPalette.spaceLg),
          _SummaryPanel(items: model.summaryItems),
          const SizedBox(height: 12),
          SizedBox(
            height: model.overlayOptions.isEmpty ? 270 : 326,
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
                                        showGrid: true,
                                        showVerticalGrid: false,
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
                                          window: state.window,
                                          localeTag: localeTag,
                                        ),
                                        tooltipTimeLabelBuilder: (ts) =>
                                            _tooltipTimeLabel(
                                          timestamp: ts,
                                          window: state.window,
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
                                      values: model.barChartValues,
                                      timestamps: model.barChartTimestamps,
                                      windowStart: model.series?.from,
                                      windowEnd: model.series?.to,
                                      color: metric.displayMode ==
                                              TelemetryHistoryMetricDisplayMode
                                                  .heatingUsage
                                          ? AppPalette.accentWarning
                                          : AppPalette.accentSuccess,
                                      showGrid: true,
                                      showVerticalGrid: false,
                                      showAxes: true,
                                      enableTouchTooltip: true,
                                      valueLabelBuilder: (v) =>
                                          _fmtValue(v, metric),
                                      xAxisLabelBuilder: (ts) => _xAxisLabel(
                                        timestamp: ts,
                                        window: state.window,
                                        localeTag: localeTag,
                                      ),
                                      tooltipTimeLabelBuilder: (ts) =>
                                          _tooltipTimeLabel(
                                        timestamp: ts,
                                        window: state.window,
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
                                          showGrid: true,
                                          showVerticalGrid: false,
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
                                            window: state.window,
                                            localeTag: localeTag,
                                          ),
                                          tooltipTimeLabelBuilder: (ts) =>
                                              _tooltipTimeLabel(
                                            timestamp: ts,
                                            window: state.window,
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
                                          showGrid: true,
                                          showVerticalGrid: false,
                                          showAxes: true,
                                          enableTouchTooltip: true,
                                          valueLabelBuilder: (v) =>
                                              _fmtValue(v, metric),
                                          xAxisLabelBuilder: (ts) =>
                                              _xAxisLabel(
                                            timestamp: ts,
                                            window: state.window,
                                            localeTag: localeTag,
                                          ),
                                          tooltipBuilder: (ts, value) =>
                                              _tooltipLabel(
                                            timestamp: ts,
                                            value: value,
                                            metric: metric,
                                            window: state.window,
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
