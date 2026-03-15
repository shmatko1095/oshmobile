import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';

class TelemetryHistoryState {
  const TelemetryHistoryState({
    required this.metrics,
    required this.comparisonMetrics,
    required this.selectedMetricIndex,
    required this.range,
    required this.loadingSeriesKeys,
    required this.seriesBySeriesKey,
    required this.errorBySeriesKey,
  });

  factory TelemetryHistoryState.initial({
    required List<TelemetryHistoryMetric> metrics,
    List<TelemetryHistoryMetric> comparisonMetrics =
        const <TelemetryHistoryMetric>[],
    required int initialMetricIndex,
    required TelemetryHistoryRange initialRange,
  }) {
    final clampedIndex =
        metrics.isEmpty ? 0 : initialMetricIndex.clamp(0, metrics.length - 1);
    return TelemetryHistoryState(
      metrics: metrics,
      comparisonMetrics: comparisonMetrics,
      selectedMetricIndex: clampedIndex,
      range: initialRange,
      loadingSeriesKeys: const <String>{},
      seriesBySeriesKey: const <String, TelemetryHistorySeries>{},
      errorBySeriesKey: const <String, String>{},
    );
  }

  final List<TelemetryHistoryMetric> metrics;
  final List<TelemetryHistoryMetric> comparisonMetrics;
  final int selectedMetricIndex;
  final TelemetryHistoryRange range;
  final Set<String> loadingSeriesKeys;
  final Map<String, TelemetryHistorySeries> seriesBySeriesKey;
  final Map<String, String> errorBySeriesKey;

  TelemetryHistoryMetric get metric => metrics[selectedMetricIndex];

  bool get hasMultipleMetrics => metrics.length > 1;
  bool get hasComparisonMetrics => comparisonMetrics.isNotEmpty;

  TelemetryHistorySeries? get series => seriesFor(metric);

  bool get isLoading => isLoadingFor(metric);

  String? get errorMessage => errorFor(metric);

  TelemetryHistorySeries? seriesFor(TelemetryHistoryMetric metric) {
    return seriesBySeriesKey[metric.seriesKey];
  }

  bool isLoadingFor(TelemetryHistoryMetric metric) {
    return loadingSeriesKeys.contains(metric.seriesKey);
  }

  String? errorFor(TelemetryHistoryMetric metric) {
    return errorBySeriesKey[metric.seriesKey];
  }

  static const Object _unset = Object();

  TelemetryHistoryState copyWith({
    List<TelemetryHistoryMetric>? metrics,
    List<TelemetryHistoryMetric>? comparisonMetrics,
    int? selectedMetricIndex,
    TelemetryHistoryRange? range,
    Object? loadingSeriesKeys = _unset,
    Object? seriesBySeriesKey = _unset,
    Object? errorBySeriesKey = _unset,
  }) {
    final nextMetrics = metrics ?? this.metrics;
    final rawIndex = selectedMetricIndex ?? this.selectedMetricIndex;
    final clampedIndex =
        nextMetrics.isEmpty ? 0 : rawIndex.clamp(0, nextMetrics.length - 1);

    return TelemetryHistoryState(
      metrics: nextMetrics,
      comparisonMetrics: comparisonMetrics ?? this.comparisonMetrics,
      selectedMetricIndex: clampedIndex,
      range: range ?? this.range,
      loadingSeriesKeys: loadingSeriesKeys == _unset
          ? this.loadingSeriesKeys
          : loadingSeriesKeys as Set<String>,
      seriesBySeriesKey: seriesBySeriesKey == _unset
          ? this.seriesBySeriesKey
          : seriesBySeriesKey as Map<String, TelemetryHistorySeries>,
      errorBySeriesKey: errorBySeriesKey == _unset
          ? this.errorBySeriesKey
          : errorBySeriesKey as Map<String, String>,
    );
  }
}
