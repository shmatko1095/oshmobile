import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_setpoint_history_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_retention_policy.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';

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
    DateTime Function()? nowLocal,
    TelemetryHistoryRetentionPolicy retentionPolicy =
        const TelemetryHistoryRetentionPolicy(),
  })  : _seriesReader = seriesReader,
        _setpointReader = setpointReader,
        _retentionPolicy = retentionPolicy,
        _nowLocal = nowLocal ??
            (nowUtc == null ? _defaultNowLocal : () => nowUtc().toLocal()),
        super(
          TelemetryHistoryState.initial(
            metrics: metrics,
            comparisonMetrics: comparisonMetrics,
            initialMetricIndex: initialMetricIndex,
            initialRange: initialRange,
            nowLocal: (nowLocal ??
                    (nowUtc == null
                        ? _defaultNowLocal
                        : () => nowUtc().toLocal()))
                .call(),
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
  final TelemetryHistoryRetentionPolicy _retentionPolicy;
  final DateTime Function() _nowLocal;
  final Map<String, int> _requestVersionBySeriesKey = <String, int>{};
  int _scopeVersion = 0;
  int _setpointRequestVersion = 0;
  TelemetryHistoryWindow? _presetWindowBeforeCustom;

  static DateTime _defaultNowLocal() => DateTime.now();

  DateTime get nowLocal => _nowLocal().toLocal();

  TelemetryHistoryRetentionPolicy get retentionPolicy => _retentionPolicy;

  bool get canGoPrevious => _retentionPolicy.canGoPrevious(
        state.window,
        nowLocal: _nowLocal(),
      );

  bool get canGoNext => state.window.canGoNext(_nowLocal());

  Future<void> load() => _loadAllMetrics();

  Future<void> refresh() => _loadAllMetrics(forceRefresh: true);

  Future<void> selectRange(TelemetryHistoryRange range) async {
    if (range == TelemetryHistoryRange.custom) {
      throw ArgumentError.value(
        range,
        'range',
        'Use selectCustomRange for a custom range.',
      );
    }
    if (range == state.range) return;
    _presetWindowBeforeCustom = null;
    await _replaceWindow(
      TelemetryHistoryWindow.current(
        range: range,
        nowLocal: _nowLocal(),
      ),
    );
  }

  Future<bool> selectCustomRange({
    required DateTime startLocal,
    required DateTime endInclusiveLocal,
  }) async {
    final window = TelemetryHistoryWindow.custom(
      startLocal: startLocal,
      endInclusiveLocal: endInclusiveLocal,
    );
    final now = _nowLocal().toLocal();
    if (!_retentionPolicy.allowsCustomWindow(window, nowLocal: now)) {
      return false;
    }

    if (state.range != TelemetryHistoryRange.custom) {
      _presetWindowBeforeCustom = state.window;
    }
    if (state.range == TelemetryHistoryRange.custom &&
        state.window.startLocal == window.startLocal &&
        state.window.endLocal == window.endLocal) {
      return true;
    }
    await _replaceWindow(window);
    return true;
  }

  Future<void> clearCustomRange() async {
    if (state.range != TelemetryHistoryRange.custom) return;
    final presetWindow = _presetWindowBeforeCustom ??
        TelemetryHistoryWindow.current(
          range: TelemetryHistoryRange.day,
          nowLocal: _nowLocal(),
        );
    _presetWindowBeforeCustom = null;
    await _replaceWindow(presetWindow);
  }

  Future<void> showPreviousPeriod() async {
    if (!canGoPrevious) return;
    await _replaceWindow(state.window.previous());
  }

  Future<void> showNextPeriod() async {
    final next = state.window.next(_nowLocal());
    if (identical(next, state.window)) return;
    await _replaceWindow(next);
  }

  Future<void> _replaceWindow(TelemetryHistoryWindow window) async {
    _scopeVersion++;
    _requestVersionBySeriesKey.clear();
    emit(
      state.copyWith(
        window: window,
        loadingSeriesKeys: <String>{},
        seriesBySeriesKey: <String, TelemetryHistorySeries>{},
        errorBySeriesKey: <String, String>{},
        setpointHistory: null,
        setpointLoading: false,
        setpointErrorMessage: null,
      ),
    );
    await _loadAllMetrics(forceRefresh: true);
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

  Future<void> _loadAllMetrics({bool forceRefresh = false}) async {
    final metrics = <TelemetryHistoryMetric>[
      ...state.metrics,
      ...state.comparisonMetrics.where(_isSeriesBackedComparisonMetric),
    ];
    final futures = <Future<void>>[
      ensureMetricsLoaded(metrics, forceRefresh: forceRefresh),
    ];
    if (state.metrics.any(_isTemperatureMetric) &&
        _setpointReader != null &&
        _hasSetpointOverlay) {
      futures.add(_loadSetpointHistory(forceRefresh: forceRefresh));
    }
    await Future.wait(futures);
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
    if (_isTemperatureMetric(metric) &&
        _setpointReader != null &&
        _hasSetpointOverlay) {
      futures.add(_loadSetpointHistory(forceRefresh: forceRefresh));
    }
    await Future.wait(futures);
  }

  Future<void> _loadSetpointHistory({bool forceRefresh = false}) async {
    final reader = _setpointReader;
    if (reader == null) return;
    if (state.setpointLoading) return;
    if (!forceRefresh &&
        state.setpointHistory != null &&
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
    final now = _nowLocal();
    try {
      final history = await reader.getSetpointHistory(
        from: state.window.queryFromUtc,
        to: state.window.queryToUtc(now),
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
    if (inFlight || (!forceRefresh && hasData && !hasError)) {
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

    final now = _nowLocal();
    final from = state.window.queryFromUtc;
    final to = state.window.queryToUtc(now);

    try {
      final series = await _seriesReader.getSeries(
        seriesKey: seriesKey,
        from: from,
        to: to,
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
    return state.comparisonMetrics.where(_isSeriesBackedComparisonMetric);
  }

  bool _isTemperatureMetric(TelemetryHistoryMetric metric) {
    return metric.kind == TelemetryHistoryMetricKind.numeric &&
        metric.seriesKey.endsWith('.temp');
  }

  bool get _hasSetpointOverlay => state.comparisonMetrics.any(
        (metric) =>
            metric.seriesKey == TelemetryHistoryMetricCatalog.targetTemp,
      );

  bool _isSeriesBackedComparisonMetric(TelemetryHistoryMetric metric) {
    return metric.seriesKey != TelemetryHistoryMetricCatalog.targetTemp;
  }
}
