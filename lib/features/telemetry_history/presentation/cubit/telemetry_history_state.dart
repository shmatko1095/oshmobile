import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';

class TelemetryHistoryState {
  const TelemetryHistoryState({
    required this.metrics,
    required this.comparisonMetrics,
    required this.selectedMetricIndex,
    required this.window,
    required this.loadingSeriesKeys,
    required this.seriesBySeriesKey,
    required this.errorBySeriesKey,
    required this.setpointHistory,
    required this.setpointLoading,
    required this.setpointErrorMessage,
  });

  factory TelemetryHistoryState.initial({
    required List<TelemetryHistoryMetric> metrics,
    List<TelemetryHistoryMetric> comparisonMetrics =
        const <TelemetryHistoryMetric>[],
    required int initialMetricIndex,
    required TelemetryHistoryRange initialRange,
    DateTime? nowLocal,
  }) {
    final clampedIndex =
        metrics.isEmpty ? 0 : initialMetricIndex.clamp(0, metrics.length - 1);
    return TelemetryHistoryState(
      metrics: metrics,
      comparisonMetrics: comparisonMetrics,
      selectedMetricIndex: clampedIndex,
      window: TelemetryHistoryWindow.current(
        range: initialRange,
        nowLocal: nowLocal ?? DateTime.now(),
      ),
      loadingSeriesKeys: const <String>{},
      seriesBySeriesKey: const <String, TelemetryHistorySeries>{},
      errorBySeriesKey: const <String, String>{},
      setpointHistory: null,
      setpointLoading: false,
      setpointErrorMessage: null,
    );
  }

  final List<TelemetryHistoryMetric> metrics;
  final List<TelemetryHistoryMetric> comparisonMetrics;
  final int selectedMetricIndex;
  final TelemetryHistoryWindow window;
  final Set<String> loadingSeriesKeys;
  final Map<String, TelemetryHistorySeries> seriesBySeriesKey;
  final Map<String, String> errorBySeriesKey;
  final TelemetrySetpointHistory? setpointHistory;
  final bool setpointLoading;
  final String? setpointErrorMessage;

  TelemetryHistoryRange get range => window.range;

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
    TelemetryHistoryWindow? window,
    Object? loadingSeriesKeys = _unset,
    Object? seriesBySeriesKey = _unset,
    Object? errorBySeriesKey = _unset,
    Object? setpointHistory = _unset,
    bool? setpointLoading,
    Object? setpointErrorMessage = _unset,
  }) {
    final nextMetrics = metrics ?? this.metrics;
    final rawIndex = selectedMetricIndex ?? this.selectedMetricIndex;
    final clampedIndex =
        nextMetrics.isEmpty ? 0 : rawIndex.clamp(0, nextMetrics.length - 1);

    return TelemetryHistoryState(
      metrics: nextMetrics,
      comparisonMetrics: comparisonMetrics ?? this.comparisonMetrics,
      selectedMetricIndex: clampedIndex,
      window: window ?? this.window,
      loadingSeriesKeys: loadingSeriesKeys == _unset
          ? this.loadingSeriesKeys
          : loadingSeriesKeys as Set<String>,
      seriesBySeriesKey: seriesBySeriesKey == _unset
          ? this.seriesBySeriesKey
          : seriesBySeriesKey as Map<String, TelemetryHistorySeries>,
      errorBySeriesKey: errorBySeriesKey == _unset
          ? this.errorBySeriesKey
          : errorBySeriesKey as Map<String, String>,
      setpointHistory: setpointHistory == _unset
          ? this.setpointHistory
          : setpointHistory as TelemetrySetpointHistory?,
      setpointLoading: setpointLoading ?? this.setpointLoading,
      setpointErrorMessage: setpointErrorMessage == _unset
          ? this.setpointErrorMessage
          : setpointErrorMessage as String?,
    );
  }
}
