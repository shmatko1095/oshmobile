import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';

class TelemetryHistoryCubit extends Cubit<TelemetryHistoryState> {
  TelemetryHistoryCubit({
    required TelemetryHistorySeriesReader seriesReader,
    required List<TelemetryHistoryMetric> metrics,
    int initialMetricIndex = 0,
    TelemetryHistoryRange initialRange = TelemetryHistoryRange.day,
    DateTime Function()? nowUtc,
  })  : _seriesReader = seriesReader,
        _nowUtc = nowUtc ?? _defaultNowUtc,
        super(
          TelemetryHistoryState.initial(
            metrics: metrics,
            initialMetricIndex: initialMetricIndex,
            initialRange: initialRange,
          ),
        ) {
    if (metrics.isEmpty) {
      throw ArgumentError.value(
        metrics,
        'metrics',
        'Telemetry history requires at least one metric.',
      );
    }
  }

  final TelemetryHistorySeriesReader _seriesReader;
  final DateTime Function() _nowUtc;
  final Map<String, int> _requestVersionBySeriesKey = <String, int>{};
  int _scopeVersion = 0;

  static DateTime _defaultNowUtc() => DateTime.now().toUtc();

  Future<void> load() => _loadMetric(state.metric);

  Future<void> refresh() => _loadMetric(state.metric, forceRefresh: true);

  Future<void> selectRange(TelemetryHistoryRange range) async {
    if (range == state.range) return;
    _scopeVersion++;
    _requestVersionBySeriesKey.clear();
    emit(
      state.copyWith(
        range: range,
        loadingSeriesKeys: <String>{},
        seriesBySeriesKey: <String, TelemetryHistorySeries>{},
        errorBySeriesKey: <String, String>{},
      ),
    );
    await _loadMetric(state.metric, forceRefresh: true);
  }

  Future<void> selectMetricIndex(int index) async {
    if (index < 0 || index >= state.metrics.length) return;
    if (index == state.selectedMetricIndex) return;
    emit(state.copyWith(selectedMetricIndex: index));
    await _loadMetric(state.metric);
  }

  Future<void> reloadMetric(TelemetryHistoryMetric metric) {
    return _loadMetric(metric, forceRefresh: true);
  }

  Future<void> _loadMetric(
    TelemetryHistoryMetric metric, {
    bool forceRefresh = false,
  }) async {
    final seriesKey = metric.seriesKey;
    final hasData = state.seriesBySeriesKey.containsKey(seriesKey);
    final hasError = state.errorBySeriesKey.containsKey(seriesKey);
    final inFlight = state.loadingSeriesKeys.contains(seriesKey);
    if (!forceRefresh && hasData && !hasError && !inFlight) {
      return;
    }

    final requestVersion = (_requestVersionBySeriesKey[seriesKey] ?? 0) + 1;
    _requestVersionBySeriesKey[seriesKey] = requestVersion;
    final scopeVersion = _scopeVersion;

    final nextLoading = <String>{...state.loadingSeriesKeys, seriesKey};
    final nextErrors = <String, String>{...state.errorBySeriesKey}
      ..remove(seriesKey);
    emit(
      state.copyWith(
        loadingSeriesKeys: nextLoading,
        errorBySeriesKey: nextErrors,
      ),
    );

    final now = _nowUtc();
    final from = now.subtract(state.range.duration);

    try {
      final series = await _seriesReader.getSeries(
        seriesKey: seriesKey,
        from: from,
        to: now,
        preferredResolution: 'auto',
      );

      if (_isStale(seriesKey, requestVersion, scopeVersion)) return;
      final loadedSeries = <String, TelemetryHistorySeries>{
        ...state.seriesBySeriesKey
      }..[seriesKey] = series;
      final loading = <String>{...state.loadingSeriesKeys}..remove(seriesKey);
      final errors = <String, String>{...state.errorBySeriesKey}
        ..remove(seriesKey);
      emit(
        state.copyWith(
          loadingSeriesKeys: loading,
          seriesBySeriesKey: loadedSeries,
          errorBySeriesKey: errors,
        ),
      );
    } catch (error) {
      if (_isStale(seriesKey, requestVersion, scopeVersion)) return;
      final loading = <String>{...state.loadingSeriesKeys}..remove(seriesKey);
      final errors = <String, String>{...state.errorBySeriesKey}..[seriesKey] =
          error.toString();
      emit(
        state.copyWith(
          loadingSeriesKeys: loading,
          errorBySeriesKey: errors,
        ),
      );
    }
  }

  bool _isStale(String seriesKey, int requestVersion, int scopeVersion) {
    if (isClosed) return true;
    if (scopeVersion != _scopeVersion) return true;
    return _requestVersionBySeriesKey[seriesKey] != requestVersion;
  }
}
