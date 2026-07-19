part of 'telemetry_history_slide_view_model.dart';

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
    required this.barChartValues,
    required this.barChartTimestamps,
    required this.numericSeries,
    required this.chartKind,
    required this.isEmpty,
    required this.chartSemanticLabel,
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
  final List<double?> barChartValues;
  final List<DateTime> barChartTimestamps;
  final List<HistoryMultiLineSeries> numericSeries;
  final TelemetryHistorySlideChartKind chartKind;
  final bool isEmpty;
  final String chartSemanticLabel;
}
