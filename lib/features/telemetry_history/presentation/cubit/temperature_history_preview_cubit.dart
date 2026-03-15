import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_state.dart';

class TemperatureHistoryPreviewCubit
    extends Cubit<TemperatureHistoryPreviewState> {
  TemperatureHistoryPreviewCubit({
    required TelemetryHistorySeriesReader seriesReader,
    Duration cacheTtl = const Duration(minutes: 2),
    DateTime Function()? nowUtc,
  })  : _seriesReader = seriesReader,
        _cacheTtl = cacheTtl,
        _nowUtc = nowUtc ?? _defaultNowUtc,
        super(const TemperatureHistoryPreviewState.initial());

  static const Duration _historyWindow = Duration(hours: 24);

  final TelemetryHistorySeriesReader _seriesReader;
  final Duration _cacheTtl;
  final DateTime Function() _nowUtc;
  final Map<String, int> _requestVersionBySeriesKey = <String, int>{};

  static DateTime _defaultNowUtc() => DateTime.now().toUtc();

  Future<void> ensureLoaded({
    required String seriesKey,
  }) async {
    final normalized = seriesKey.trim();
    if (normalized.isEmpty) return;

    final current = state.entryOf(normalized);
    final now = _nowUtc();
    if (_isFresh(current, now)) {
      return;
    }

    final requestVersion = (_requestVersionBySeriesKey[normalized] ?? 0) + 1;
    _requestVersionBySeriesKey[normalized] = requestVersion;
    emit(
      state.upsert(
        normalized,
        TemperatureHistoryPreviewEntry.loading(updatedAt: current?.updatedAt),
      ),
    );

    final to = _nowUtc();
    final from = to.subtract(_historyWindow);

    try {
      final series = await _seriesReader.getSeries(
        seriesKey: normalized,
        from: from,
        to: to,
        preferredResolution: 'auto',
      );
      if (_isStaleResponse(normalized, requestVersion)) return;

      final samples = _numericSamples(series);
      final values =
          samples.map((sample) => sample.value).toList(growable: false);
      final timestamps =
          samples.map((sample) => sample.timestamp).toList(growable: false);
      final entry = TemperatureHistoryPreviewEntry(
        status: TemperatureHistoryPreviewStatus.ready,
        values: values,
        timestamps: timestamps,
        lastValue: values.isEmpty ? null : values.last,
        updatedAt: _nowUtc(),
        windowStart: series.from,
        windowEnd: series.to,
      );
      emit(state.upsert(normalized, entry));
    } catch (error) {
      if (_isStaleResponse(normalized, requestVersion)) return;
      emit(
        state.upsert(
          normalized,
          TemperatureHistoryPreviewEntry(
            status: TemperatureHistoryPreviewStatus.error,
            values: const <double>[],
            timestamps: const <DateTime>[],
            lastValue: null,
            updatedAt: _nowUtc(),
            windowStart: null,
            windowEnd: null,
            errorMessage: error.toString(),
          ),
        ),
      );
    }
  }

  bool shouldLoad(String seriesKey) {
    final normalized = seriesKey.trim();
    if (normalized.isEmpty) return false;
    final current = state.entryOf(normalized);
    return !_isFresh(current, _nowUtc());
  }

  bool _isFresh(TemperatureHistoryPreviewEntry? entry, DateTime now) {
    if (entry == null) return false;
    if (entry.status == TemperatureHistoryPreviewStatus.loading) return true;
    final updatedAt = entry.updatedAt;
    if (updatedAt == null) return false;
    return now.difference(updatedAt) <= _cacheTtl;
  }

  bool _isStaleResponse(String seriesKey, int requestVersion) {
    if (isClosed) return true;
    return _requestVersionBySeriesKey[seriesKey] != requestVersion;
  }

  List<_PreviewNumericSample> _numericSamples(TelemetryHistorySeries series) {
    return series.points
        .map((point) {
          final value = _numericValueFromPoint(point);
          if (value == null) return null;
          return _PreviewNumericSample(
            value: value,
            timestamp: point.bucketStart.toUtc(),
          );
        })
        .whereType<_PreviewNumericSample>()
        .toList(growable: false);
  }

  double? _numericValueFromPoint(TelemetryHistoryPoint point) {
    return point.avgValue ??
        point.lastNumericValue ??
        point.maxValue ??
        point.minValue;
  }
}

class _PreviewNumericSample {
  const _PreviewNumericSample({
    required this.value,
    required this.timestamp,
  });

  final double value;
  final DateTime timestamp;
}
