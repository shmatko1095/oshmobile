import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_setpoint_history_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';

class TelemetryHistoryCubit extends Cubit<TelemetryHistoryState> {
  TelemetryHistoryCubit({
    required TelemetryHistorySeriesReader seriesReader,
    TelemetrySetpointHistoryReader? setpointReader,
    required List<TelemetryHistoryMetric> metrics,
    List<TelemetryHistoryMetric> comparisonMetrics =
        const <TelemetryHistoryMetric>[],
    int initialMetricIndex = 0,
    TelemetryHistoryRange initialRange = TelemetryHistoryRange.day,
    DateTime Function()? nowUtc,
  })  : _seriesReader = seriesReader,
        _setpointReader = setpointReader,
        _nowUtc = nowUtc ?? _defaultNowUtc,
        super(
          TelemetryHistoryState.initial(
            metrics: metrics,
            comparisonMetrics: comparisonMetrics,
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
  final TelemetrySetpointHistoryReader? _setpointReader;
  final DateTime Function() _nowUtc;
  final Map<String, int> _requestVersionBySeriesKey = <String, int>{};
  int _scopeVersion = 0;
  int _setpointRequestVersion = 0;

  static DateTime _defaultNowUtc() => DateTime.now().toUtc();

  Future<void> load() => _loadVisibleMetric(state.metric);

  Future<void> refresh() =>
      _loadVisibleMetric(state.metric, forceRefresh: true);

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
        setpointHistory: null,
        setpointLoading: false,
        setpointErrorMessage: null,
      ),
    );
    await _loadVisibleMetric(state.metric, forceRefresh: true);
  }

  Future<void> selectMetricIndex(int index) async {
    if (index < 0 || index >= state.metrics.length) return;
    if (index == state.selectedMetricIndex) return;
    emit(state.copyWith(selectedMetricIndex: index));
    await _loadVisibleMetric(state.metric);
  }

  Future<void> reloadMetric(TelemetryHistoryMetric metric) {
    return _loadVisibleMetric(metric, forceRefresh: true);
  }

  Future<void> ensureMetricsLoaded(
    Iterable<TelemetryHistoryMetric> metrics, {
    bool forceRefresh = false,
  }) async {
    final uniqueBySeriesKey = <String, TelemetryHistoryMetric>{};
    for (final metric in metrics) {
      uniqueBySeriesKey[metric.seriesKey] = metric;
    }
    if (uniqueBySeriesKey.isEmpty) return;
    await Future.wait(
      uniqueBySeriesKey.values.map(
        (metric) => _loadMetric(metric, forceRefresh: forceRefresh),
      ),
    );
  }

  Future<void> _loadVisibleMetric(
    TelemetryHistoryMetric metric, {
    bool forceRefresh = false,
  }) async {
    final futures = <Future<void>>[
      ensureMetricsLoaded(
        <TelemetryHistoryMetric>[
          metric,
          ..._comparisonMetricsFor(metric),
        ],
        forceRefresh: forceRefresh,
      ),
    ];
    if (_isTemperatureMetric(metric) && _setpointReader != null) {
      futures.add(_loadSetpointHistory(forceRefresh: forceRefresh));
    }
    await Future.wait(futures);
  }

  Future<void> _loadSetpointHistory({bool forceRefresh = false}) async {
    final reader = _setpointReader;
    if (reader == null) return;
    if (!forceRefresh &&
        state.setpointHistory != null &&
        !state.setpointLoading &&
        state.setpointErrorMessage == null) {
      return;
    }
    final requestVersion = ++_setpointRequestVersion;
    final scopeVersion = _scopeVersion;
    emit(
      state.copyWith(
        setpointLoading: true,
        setpointErrorMessage: null,
      ),
    );
    final now = _nowUtc();
    try {
      final history = await reader.getSetpointHistory(
        from: now.subtract(state.range.duration),
        to: now,
        preferredResolution: 'auto',
      );
      if (isClosed ||
          scopeVersion != _scopeVersion ||
          requestVersion != _setpointRequestVersion) {
        return;
      }
      emit(
        state.copyWith(
          setpointHistory: history,
          setpointLoading: false,
          setpointErrorMessage: null,
        ),
      );
    } catch (error) {
      if (isClosed ||
          scopeVersion != _scopeVersion ||
          requestVersion != _setpointRequestVersion) {
        return;
      }
      emit(
        state.copyWith(
          setpointLoading: false,
          setpointErrorMessage: error.toString(),
        ),
      );
    }
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

  Iterable<TelemetryHistoryMetric> _comparisonMetricsFor(
    TelemetryHistoryMetric metric,
  ) {
    if (!_isTemperatureMetric(metric)) {
      return const <TelemetryHistoryMetric>[];
    }
    return state.comparisonMetrics;
  }

  bool _isTemperatureMetric(TelemetryHistoryMetric metric) {
    return metric.kind == TelemetryHistoryMetricKind.numeric &&
        metric.seriesKey.endsWith('.temp');
  }
}
