import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/temperature_history_preview_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_state.dart';

class TemperatureHistoryPreviewCubit
    extends Cubit<TemperatureHistoryPreviewState> {
  TemperatureHistoryPreviewCubit({
    required TelemetryHistorySeriesReader seriesReader,
    Duration cacheTtl = const Duration(minutes: 2),
    TemperatureHistoryPreviewCache? persistentCache,
    String? persistentCacheNamespace,
    Duration persistentCacheMaxAge = const Duration(days: 7),
    DateTime Function()? nowUtc,
  })  : _seriesReader = seriesReader,
        _cacheTtl = cacheTtl,
        _persistentCache = persistentCache,
        _persistentCacheNamespace = persistentCacheNamespace?.trim(),
        _persistentCacheMaxAge = persistentCacheMaxAge,
        _nowUtc = nowUtc ?? _defaultNowUtc,
        super(const TemperatureHistoryPreviewState.initial());

  static const Duration _historyWindow = Duration(hours: 24);

  final TelemetryHistorySeriesReader _seriesReader;
  final Duration _cacheTtl;
  final TemperatureHistoryPreviewCache? _persistentCache;
  final String? _persistentCacheNamespace;
  final Duration _persistentCacheMaxAge;
  final DateTime Function() _nowUtc;
  final Map<String, int> _requestVersionBySeriesKey = <String, int>{};

  static DateTime _defaultNowUtc() => DateTime.now().toUtc();

  Future<void> ensureLoaded({
    required String seriesKey,
  }) async {
    final normalized = seriesKey.trim();
    if (normalized.isEmpty) return;

    var current = state.entryOf(normalized);
    final now = _nowUtc();
    if (_isFresh(current, now)) {
      return;
    }

    if (current == null || current.values.isEmpty) {
      final cached = await _readPersistentCache(normalized, now);
      if (isClosed) return;

      current = state.entryOf(normalized);
      if (_isFresh(current, _nowUtc())) {
        return;
      }

      if ((current == null || current.values.isEmpty) && cached != null) {
        final cachedEntry = _entryFromCache(cached);
        emit(state.upsert(normalized, cachedEntry));
        current = cachedEntry;
      }
    }

    current = state.entryOf(normalized);
    if (current?.status == TemperatureHistoryPreviewStatus.loading) {
      return;
    }

    final requestVersion = (_requestVersionBySeriesKey[normalized] ?? 0) + 1;
    _requestVersionBySeriesKey[normalized] = requestVersion;
    emit(
      state.upsert(
        normalized,
        TemperatureHistoryPreviewEntry.loading(
          updatedAt: current?.updatedAt,
          values: current?.values ?? const <double>[],
          timestamps: current?.timestamps ?? const <DateTime>[],
          lastValue: current?.lastValue,
          windowStart: current?.windowStart,
          windowEnd: current?.windowEnd,
          isFromPersistentCache: current?.isFromPersistentCache ?? false,
        ),
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
      await _writePersistentCache(normalized, entry);
      emit(state.upsert(normalized, entry));
    } catch (error) {
      if (_isStaleResponse(normalized, requestVersion)) return;
      final fallback = state.entryOf(normalized);
      emit(
        state.upsert(
          normalized,
          TemperatureHistoryPreviewEntry(
            status: TemperatureHistoryPreviewStatus.error,
            values: fallback?.values ?? const <double>[],
            timestamps: fallback?.timestamps ?? const <DateTime>[],
            lastValue: fallback?.lastValue,
            updatedAt: _nowUtc(),
            windowStart: fallback?.windowStart,
            windowEnd: fallback?.windowEnd,
            errorMessage: error.toString(),
            isFromPersistentCache: fallback?.isFromPersistentCache ?? false,
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
    if (entry.status != TemperatureHistoryPreviewStatus.ready) return false;
    if (entry.isFromPersistentCache) return false;
    final updatedAt = entry.updatedAt;
    if (updatedAt == null) return false;
    return now.difference(updatedAt) <= _cacheTtl;
  }

  Future<TemperatureHistoryPreviewCacheRecord?> _readPersistentCache(
    String seriesKey,
    DateTime now,
  ) async {
    final cache = _persistentCache;
    final namespace = _persistentCacheNamespace;
    if (cache == null || namespace == null || namespace.isEmpty) {
      return null;
    }

    try {
      return await cache.read(
        namespace: namespace,
        seriesKey: seriesKey,
        nowUtc: now,
        maxAge: _persistentCacheMaxAge,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writePersistentCache(
    String seriesKey,
    TemperatureHistoryPreviewEntry entry,
  ) async {
    final cache = _persistentCache;
    final namespace = _persistentCacheNamespace;
    if (cache == null || namespace == null || namespace.isEmpty) return;

    try {
      if (entry.values.isEmpty) {
        await cache.remove(namespace: namespace, seriesKey: seriesKey);
        return;
      }

      await cache.write(
        namespace: namespace,
        seriesKey: seriesKey,
        record: TemperatureHistoryPreviewCacheRecord(
          values: entry.values,
          timestamps: entry.timestamps,
          savedAt: entry.updatedAt ?? _nowUtc(),
          windowStart: entry.windowStart,
          windowEnd: entry.windowEnd,
        ),
      );
    } catch (_) {
      // Preview cache is best-effort. A storage failure must not hide live data.
    }
  }

  TemperatureHistoryPreviewEntry _entryFromCache(
    TemperatureHistoryPreviewCacheRecord record,
  ) {
    return TemperatureHistoryPreviewEntry(
      status: TemperatureHistoryPreviewStatus.ready,
      values: record.values,
      timestamps: record.timestamps,
      lastValue: record.lastValue,
      updatedAt: record.savedAt,
      windowStart: record.windowStart,
      windowEnd: record.windowEnd,
      isFromPersistentCache: true,
    );
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
