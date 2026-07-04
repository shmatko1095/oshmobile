import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/temperature_history_preview_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_state.dart';

class _CountingTelemetryHistoryApi implements TelemetryHistorySeriesReader {
  int calls = 0;

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) async {
    calls++;
    return TelemetryHistorySeries(
      deviceId: 'd',
      serial: 'sn',
      seriesKey: seriesKey,
      resolution: '5m',
      from: from,
      to: to,
      points: <TelemetryHistoryPoint>[
        TelemetryHistoryPoint(
          bucketStart: from,
          samplesCount: 1,
          avgValue: 28.5,
        ),
      ],
    );
  }
}

void main() {
  test('uses cache and does not reload fresh preview', () async {
    final api = _CountingTelemetryHistoryApi();
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
    final cubit = TemperatureHistoryPreviewCubit(
      seriesReader: api,
      cacheTtl: const Duration(minutes: 2),
      nowUtc: () => now,
    );

    await cubit.ensureLoaded(seriesKey: 'climate_sensors.floor.temp');
    await cubit.ensureLoaded(seriesKey: 'climate_sensors.floor.temp');

    expect(api.calls, 1);
    final entry = cubit.state.entryOf('climate_sensors.floor.temp');
    expect(entry, isNotNull);
    expect(entry!.values, hasLength(1));
    expect(entry.timestamps, hasLength(1));
    expect(entry.windowStart, isNotNull);
    expect(entry.windowEnd, isNotNull);
    expect(entry.lastValue, 28.5);

    await cubit.close();
  });

  test('shows persistent cache immediately and refreshes it in background',
      () async {
    const seriesKey = 'climate_sensors.floor.temp';
    const namespace = 'device-sn';
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
    final api = _QueuedTelemetryHistoryApi();
    final cache = _MemoryTemperatureHistoryPreviewCache();
    await cache.write(
      namespace: namespace,
      seriesKey: seriesKey,
      record: TemperatureHistoryPreviewCacheRecord(
        values: const <double>[20.1],
        timestamps: <DateTime>[now.subtract(const Duration(hours: 1))],
        savedAt: now.subtract(const Duration(hours: 1)),
        windowStart: now.subtract(const Duration(hours: 24)),
        windowEnd: now,
      ),
    );
    final cubit = TemperatureHistoryPreviewCubit(
      seriesReader: api,
      persistentCache: cache,
      persistentCacheNamespace: namespace,
      nowUtc: () => now,
    );

    final load = cubit.ensureLoaded(seriesKey: seriesKey);
    await Future<void>.delayed(Duration.zero);

    expect(api.calls, 1);
    final cachedEntry = cubit.state.entryOf(seriesKey);
    expect(cachedEntry, isNotNull);
    expect(cachedEntry!.status, TemperatureHistoryPreviewStatus.loading);
    expect(cachedEntry.values, const <double>[20.1]);
    expect(cachedEntry.isFromPersistentCache, isTrue);

    api.completeNext(
      _series(
        seriesKey: seriesKey,
        from: now.subtract(const Duration(hours: 24)),
        to: now,
        values: const <double>[22.4],
      ),
    );
    await load;

    final freshEntry = cubit.state.entryOf(seriesKey);
    expect(freshEntry, isNotNull);
    expect(freshEntry!.status, TemperatureHistoryPreviewStatus.ready);
    expect(freshEntry.values, const <double>[22.4]);
    expect(freshEntry.isFromPersistentCache, isFalse);

    final stored = await cache.read(
      namespace: namespace,
      seriesKey: seriesKey,
      nowUtc: now,
      maxAge: const Duration(days: 7),
    );
    expect(stored?.values, const <double>[22.4]);

    await cubit.close();
  });

  test('ignores expired persistent cache', () async {
    const seriesKey = 'climate_sensors.floor.temp';
    const namespace = 'device-sn';
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
    final api = _CountingTelemetryHistoryApi();
    final cache = _MemoryTemperatureHistoryPreviewCache();
    await cache.write(
      namespace: namespace,
      seriesKey: seriesKey,
      record: TemperatureHistoryPreviewCacheRecord(
        values: const <double>[20.1],
        timestamps: <DateTime>[now.subtract(const Duration(days: 8))],
        savedAt: now.subtract(const Duration(days: 8)),
        windowStart: now.subtract(const Duration(days: 9)),
        windowEnd: now.subtract(const Duration(days: 8)),
      ),
    );
    final cubit = TemperatureHistoryPreviewCubit(
      seriesReader: api,
      persistentCache: cache,
      persistentCacheNamespace: namespace,
      nowUtc: () => now,
    );

    await cubit.ensureLoaded(seriesKey: seriesKey);

    final entry = cubit.state.entryOf(seriesKey);
    expect(api.calls, 1);
    expect(entry?.values, const <double>[28.5]);
    expect(entry?.isFromPersistentCache, isFalse);
    expect(
      await cache.read(
        namespace: namespace,
        seriesKey: seriesKey,
        nowUtc: now,
        maxAge: const Duration(days: 7),
      ),
      isNotNull,
    );

    await cubit.close();
  });

  test('removes persistent cache when server returns no values', () async {
    const seriesKey = 'climate_sensors.floor.temp';
    const namespace = 'device-sn';
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
    final api = _QueuedTelemetryHistoryApi();
    final cache = _MemoryTemperatureHistoryPreviewCache();
    await cache.write(
      namespace: namespace,
      seriesKey: seriesKey,
      record: TemperatureHistoryPreviewCacheRecord(
        values: const <double>[20.1],
        timestamps: <DateTime>[now.subtract(const Duration(hours: 1))],
        savedAt: now.subtract(const Duration(hours: 1)),
        windowStart: now.subtract(const Duration(hours: 24)),
        windowEnd: now,
      ),
    );
    final cubit = TemperatureHistoryPreviewCubit(
      seriesReader: api,
      persistentCache: cache,
      persistentCacheNamespace: namespace,
      nowUtc: () => now,
    );

    final load = cubit.ensureLoaded(seriesKey: seriesKey);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.entryOf(seriesKey)?.values, const <double>[20.1]);

    api.completeNext(
      TelemetryHistorySeries(
        deviceId: 'd',
        serial: 'sn',
        seriesKey: seriesKey,
        resolution: '5m',
        from: now.subtract(const Duration(hours: 24)),
        to: now,
        points: const <TelemetryHistoryPoint>[],
      ),
    );
    await load;

    final entry = cubit.state.entryOf(seriesKey);
    expect(entry?.status, TemperatureHistoryPreviewStatus.ready);
    expect(entry?.values, isEmpty);
    expect(
      await cache.read(
        namespace: namespace,
        seriesKey: seriesKey,
        nowUtc: now,
        maxAge: const Duration(days: 7),
      ),
      isNull,
    );

    await cubit.close();
  });
}

TelemetryHistorySeries _series({
  required String seriesKey,
  required DateTime from,
  required DateTime to,
  required List<double> values,
}) {
  return TelemetryHistorySeries(
    deviceId: 'd',
    serial: 'sn',
    seriesKey: seriesKey,
    resolution: '5m',
    from: from,
    to: to,
    points: <TelemetryHistoryPoint>[
      for (var i = 0; i < values.length; i++)
        TelemetryHistoryPoint(
          bucketStart: from.add(Duration(minutes: i * 5)),
          samplesCount: 1,
          avgValue: values[i],
        ),
    ],
  );
}

final class _QueuedTelemetryHistoryApi implements TelemetryHistorySeriesReader {
  final List<_TelemetryHistoryRequest> requests = <_TelemetryHistoryRequest>[];

  int get calls => requests.length;

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) {
    final request = _TelemetryHistoryRequest(
      seriesKey: seriesKey,
      from: from,
      to: to,
    );
    requests.add(request);
    return request.completer.future;
  }

  void completeNext(TelemetryHistorySeries series) {
    final request = requests.firstWhere(
      (request) => !request.completer.isCompleted,
    );
    request.completer.complete(series);
  }
}

final class _TelemetryHistoryRequest {
  _TelemetryHistoryRequest({
    required this.seriesKey,
    required this.from,
    required this.to,
  });

  final String seriesKey;
  final DateTime from;
  final DateTime to;
  final Completer<TelemetryHistorySeries> completer =
      Completer<TelemetryHistorySeries>();
}

final class _MemoryTemperatureHistoryPreviewCache
    implements TemperatureHistoryPreviewCache {
  final Map<String, TemperatureHistoryPreviewCacheRecord> records =
      <String, TemperatureHistoryPreviewCacheRecord>{};

  @override
  Future<TemperatureHistoryPreviewCacheRecord?> read({
    required String namespace,
    required String seriesKey,
    required DateTime nowUtc,
    required Duration maxAge,
  }) async {
    final key = _key(namespace, seriesKey);
    final record = records[key];
    if (record == null) return null;
    if (nowUtc.difference(record.savedAt) > maxAge) {
      records.remove(key);
      return null;
    }
    return record;
  }

  @override
  Future<void> write({
    required String namespace,
    required String seriesKey,
    required TemperatureHistoryPreviewCacheRecord record,
  }) async {
    records[_key(namespace, seriesKey)] = record;
  }

  @override
  Future<void> remove({
    required String namespace,
    required String seriesKey,
  }) async {
    records.remove(_key(namespace, seriesKey));
  }

  String _key(String namespace, String seriesKey) => '$namespace::$seriesKey';
}
