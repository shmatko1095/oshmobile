import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/core/configuration/app_polling_intervals.dart';
import 'package:oshmobile/core/configuration/power_meter_series_keys.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_state.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/daily_energy_usage_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_series.dart';

void main() {
  test('requests rolling 24h aggregate and reads energy sum value', () async {
    final now = DateTime.utc(2026, 3, 14, 10);
    late TelemetryAggregateQuery capturedQuery;
    final api = _FakeTelemetryHistoryApi(
      onAggregate: (query) async {
        capturedQuery = query;
        return _aggregate(
          from: query.from,
          to: query.to,
          energyWh: 1000,
        );
      },
    );
    final cubit = DailyEnergyUsageCubit(
      telemetryHistory: api,
      nowUtc: () => now,
    );
    addTearDown(cubit.close);

    await cubit.ensureLoaded();

    expect(capturedQuery.seriesKeys, const <String>[
      PowerMeterSeriesKeys.energyWhDelta,
    ]);
    expect(capturedQuery.from, now.subtract(const Duration(hours: 24)));
    expect(capturedQuery.to, now);
    expect(capturedQuery.preferredResolution, 'auto');
    expect(cubit.state.status, DailyEnergyUsageStatus.ready);
    expect(cubit.state.energyWh, 1000);
  });

  test('uses the aggregate series key supplied by configuration', () async {
    const configuredSeriesKey = 'custom.energy_delta';
    final now = DateTime.utc(2026, 3, 14, 10);
    late TelemetryAggregateQuery capturedQuery;
    final api = _FakeTelemetryHistoryApi(
      onAggregate: (query) async {
        capturedQuery = query;
        return _aggregate(
          from: query.from,
          to: query.to,
          energyWh: 750,
          seriesKey: configuredSeriesKey,
        );
      },
    );
    final cubit = DailyEnergyUsageCubit(
      telemetryHistory: api,
      aggregateSeriesKey: configuredSeriesKey,
      nowUtc: () => now,
    );
    addTearDown(cubit.close);

    await cubit.ensureLoaded();

    expect(capturedQuery.seriesKeys, const <String>[configuredSeriesKey]);
    expect(cubit.state.energyWh, 750);
  });

  test('emits cached value before refreshing from backend', () async {
    final now = DateTime.utc(2026, 3, 14, 10);
    final completer = Completer<TelemetryAggregate>();
    final api = _FakeTelemetryHistoryApi(
      onAggregate: (query) => completer.future,
    );
    final cache = _MemoryDailyEnergyUsageCache()
      ..record = DailyEnergyUsageCacheRecord(
        energyWh: 500,
        savedAt: now.subtract(const Duration(minutes: 20)),
        windowStart: now.subtract(const Duration(hours: 25)),
        windowEnd: now.subtract(const Duration(hours: 1)),
      );
    final cubit = DailyEnergyUsageCubit(
      telemetryHistory: api,
      persistentCache: cache,
      persistentCacheNamespace: 'SN-1',
      nowUtc: () => now,
    );
    addTearDown(cubit.close);

    final load = cubit.ensureLoaded();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, DailyEnergyUsageStatus.loading);
    expect(cubit.state.energyWh, 500);
    expect(cubit.state.isFromPersistentCache, isTrue);

    completer.complete(
      _aggregate(
        from: now.subtract(const Duration(hours: 24)),
        to: now,
        energyWh: 1000,
      ),
    );
    await load;

    expect(cubit.state.status, DailyEnergyUsageStatus.ready);
    expect(cubit.state.energyWh, 1000);
    expect(cubit.state.isFromPersistentCache, isFalse);
    expect(cache.record?.energyWh, 1000);
  });

  test('keeps cached value when backend refresh fails', () async {
    final now = DateTime.utc(2026, 3, 14, 10);
    final api = _FakeTelemetryHistoryApi(
      onAggregate: (_) async => throw StateError('offline'),
    );
    final cache = _MemoryDailyEnergyUsageCache()
      ..record = DailyEnergyUsageCacheRecord(
        energyWh: 500,
        savedAt: now.subtract(const Duration(minutes: 20)),
        windowStart: now.subtract(const Duration(hours: 25)),
        windowEnd: now.subtract(const Duration(hours: 1)),
      );
    final cubit = DailyEnergyUsageCubit(
      telemetryHistory: api,
      persistentCache: cache,
      persistentCacheNamespace: 'SN-1',
      nowUtc: () => now,
    );
    addTearDown(cubit.close);

    await cubit.ensureLoaded();

    expect(cubit.state.status, DailyEnergyUsageStatus.error);
    expect(cubit.state.energyWh, 500);
    expect(cubit.state.errorMessage, contains('offline'));
  });

  testWidgets('polls backend while active and stops after close',
      (tester) async {
    final now = DateTime.utc(2026, 3, 14, 10);
    var requestCount = 0;
    final api = _FakeTelemetryHistoryApi(
      onAggregate: (query) async {
        requestCount += 1;
        return _aggregate(
          from: query.from,
          to: query.to,
          energyWh: requestCount * 1000,
        );
      },
    );
    final cubit = DailyEnergyUsageCubit(
      telemetryHistory: api,
      nowUtc: () => now,
    );

    cubit.startPolling();
    await tester.pump();

    expect(requestCount, 1);
    expect(cubit.state.energyWh, 1000);

    await tester.pump(AppPollingIntervals.deviceData);
    await tester.pump();

    expect(requestCount, 2);
    expect(cubit.state.energyWh, 2000);

    await cubit.close();
    await tester.pump(const Duration(seconds: 2));

    expect(requestCount, 2);
  });
}

TelemetryAggregate _aggregate({
  required DateTime from,
  required DateTime to,
  required double energyWh,
  String seriesKey = PowerMeterSeriesKeys.energyWhDelta,
}) {
  return TelemetryAggregate(
    deviceId: 'device-1',
    serial: 'SN-1',
    resolution: '5m',
    from: from,
    to: to,
    series: <TelemetryAggregateSeries>[
      TelemetryAggregateSeries(
        seriesKey: seriesKey,
        valueType: 'numeric',
        unit: 'Wh',
        samplesCount: 24,
        sumValue: energyWh,
      ),
    ],
  );
}

class _FakeTelemetryHistoryApi implements DeviceTelemetryHistoryApi {
  _FakeTelemetryHistoryApi({
    required this.onAggregate,
  });

  final Future<TelemetryAggregate> Function(TelemetryAggregateQuery query)
      onAggregate;

  @override
  Future<TelemetryAggregate> getAggregate({
    required TelemetryAggregateQuery query,
  }) {
    return onAggregate(query);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryDailyEnergyUsageCache implements DailyEnergyUsageCache {
  DailyEnergyUsageCacheRecord? record;

  @override
  Future<DailyEnergyUsageCacheRecord?> read({
    required String namespace,
    required String seriesKey,
    required DateTime nowUtc,
    required Duration maxAge,
  }) async {
    final current = record;
    if (current == null) return null;
    if (nowUtc.difference(current.savedAt) > maxAge) {
      record = null;
      return null;
    }
    return current;
  }

  @override
  Future<void> write({
    required String namespace,
    required String seriesKey,
    required DailyEnergyUsageCacheRecord record,
  }) async {
    this.record = record;
  }

  @override
  Future<void> remove({
    required String namespace,
    required String seriesKey,
  }) async {
    record = null;
  }
}
