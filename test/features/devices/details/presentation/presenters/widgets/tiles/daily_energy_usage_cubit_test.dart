import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/configuration/app_polling_intervals.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_energy_usage_state.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/daily_energy_usage_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/energy_usage_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';

void main() {
  test('requests rolling 24h usage and reads backend total', () async {
    final now = DateTime.utc(2026, 3, 14, 10);
    late TelemetryUsageQuery capturedQuery;
    final api = _FakeEnergyUsageReader(
      onUsage: (query) async {
        capturedQuery = query;
        return _usage(
          from: query.from,
          to: query.to,
          totalKwh: 1,
        );
      },
    );
    final cubit = DailyEnergyUsageCubit(
      energyUsageReader: api,
      nowUtc: () => now,
    );
    addTearDown(cubit.close);

    await cubit.ensureLoaded();

    expect(capturedQuery.from, now.subtract(const Duration(hours: 24)));
    expect(capturedQuery.to, now);
    expect(capturedQuery.bucket, isNull);
    expect(capturedQuery.timezone, isNull);
    expect(cubit.state.status, DailyEnergyUsageStatus.ready);
    expect(cubit.state.energyWh, 1000);
  });

  test('keeps unavailable backend total as missing data', () async {
    final now = DateTime.utc(2026, 3, 14, 10);
    final api = _FakeEnergyUsageReader(
      onUsage: (query) async {
        return _usage(
          from: query.from,
          to: query.to,
          totalKwh: null,
          coverageRatio: 0.89,
        );
      },
    );
    final cubit = DailyEnergyUsageCubit(
      energyUsageReader: api,
      nowUtc: () => now,
    );
    addTearDown(cubit.close);

    await cubit.ensureLoaded();

    expect(cubit.state.energyWh, isNull);
  });

  test('emits cached value before refreshing from backend', () async {
    final now = DateTime.utc(2026, 3, 14, 10);
    final completer = Completer<EnergyUsage>();
    final api = _FakeEnergyUsageReader(
      onUsage: (query) => completer.future,
    );
    final cache = _MemoryDailyEnergyUsageCache()
      ..record = DailyEnergyUsageCacheRecord(
        energyWh: 500,
        savedAt: now.subtract(const Duration(minutes: 20)),
        windowStart: now.subtract(const Duration(hours: 25)),
        windowEnd: now.subtract(const Duration(hours: 1)),
      );
    final cubit = DailyEnergyUsageCubit(
      energyUsageReader: api,
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
      _usage(
        from: now.subtract(const Duration(hours: 24)),
        to: now,
        totalKwh: 1,
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
    final api = _FakeEnergyUsageReader(
      onUsage: (_) async => throw StateError('offline'),
    );
    final cache = _MemoryDailyEnergyUsageCache()
      ..record = DailyEnergyUsageCacheRecord(
        energyWh: 500,
        savedAt: now.subtract(const Duration(minutes: 20)),
        windowStart: now.subtract(const Duration(hours: 25)),
        windowEnd: now.subtract(const Duration(hours: 1)),
      );
    final cubit = DailyEnergyUsageCubit(
      energyUsageReader: api,
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
    final api = _FakeEnergyUsageReader(
      onUsage: (query) async {
        requestCount += 1;
        return _usage(
          from: query.from,
          to: query.to,
          totalKwh: requestCount.toDouble(),
        );
      },
    );
    final cubit = DailyEnergyUsageCubit(
      energyUsageReader: api,
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

EnergyUsage _usage({
  required DateTime from,
  required DateTime to,
  required double? totalKwh,
  double coverageRatio = 1,
}) {
  return EnergyUsage(
    deviceId: 'device-1',
    serial: 'SN-1',
    from: from,
    to: to,
    bucket: '',
    timezone: 'UTC',
    availableFrom: from,
    coverageRatio: coverageRatio,
    totalKwh: totalKwh,
    averageBucketKwh: null,
    peakBucketKwh: null,
    peakBucketFrom: null,
    points: const [],
  );
}

class _FakeEnergyUsageReader implements EnergyUsageReader {
  _FakeEnergyUsageReader({
    required this.onUsage,
  });

  final Future<EnergyUsage> Function(TelemetryUsageQuery query) onUsage;

  @override
  Future<EnergyUsage> getEnergyUsage({
    required TelemetryUsageQuery query,
  }) {
    return onUsage(query);
  }
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
