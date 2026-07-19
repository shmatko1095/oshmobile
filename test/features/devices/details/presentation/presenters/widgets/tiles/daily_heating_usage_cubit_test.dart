import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/configuration/app_polling_intervals.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_heating_usage_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_heating_usage_state.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/heating_usage_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';

void main() {
  test('requests rolling 24h and displays backend load factor', () async {
    final now = DateTime.utc(2026, 7, 19, 10);
    late TelemetryUsageQuery capturedQuery;
    final reader = _FakeHeatingUsageReader((query) async {
      capturedQuery = query;
      return _usage(query, loadFactorPercent: 35);
    });
    final cubit = DailyHeatingUsageCubit(
      heatingUsageReader: reader,
      nowUtc: () => now,
    );
    addTearDown(cubit.close);

    await cubit.ensureLoaded();

    expect(capturedQuery.from, now.subtract(const Duration(hours: 24)));
    expect(capturedQuery.to, now);
    expect(capturedQuery.bucket, isNull);
    expect(capturedQuery.timezone, isNull);
    expect(cubit.state.status, DailyHeatingUsageStatus.ready);
    expect(cubit.state.loadFactorPercent, 35);
  });

  test('keeps low-coverage backend value unavailable', () async {
    final now = DateTime.utc(2026, 7, 19, 10);
    final cubit = DailyHeatingUsageCubit(
      heatingUsageReader: _FakeHeatingUsageReader(
        (query) async => _usage(
          query,
          loadFactorPercent: null,
          coverageRatio: 0.89,
        ),
      ),
      nowUtc: () => now,
    );
    addTearDown(cubit.close);

    await cubit.ensureLoaded();

    expect(cubit.state.status, DailyHeatingUsageStatus.ready);
    expect(cubit.state.coverageRatio, 0.89);
    expect(cubit.state.loadFactorPercent, isNull);
  });

  testWidgets('polls while active and stops after close', (tester) async {
    final now = DateTime.utc(2026, 7, 19, 10);
    var requestCount = 0;
    final cubit = DailyHeatingUsageCubit(
      heatingUsageReader: _FakeHeatingUsageReader((query) async {
        requestCount += 1;
        return _usage(query, loadFactorPercent: requestCount.toDouble());
      }),
      nowUtc: () => now,
    );

    cubit.startPolling();
    await tester.pump();
    expect(requestCount, 1);

    await tester.pump(AppPollingIntervals.deviceData);
    await tester.pump();
    expect(requestCount, 2);

    await cubit.close();
    await tester.pump(const Duration(seconds: 2));
    expect(requestCount, 2);
  });
}

HeatingUsage _usage(
  TelemetryUsageQuery query, {
  required double? loadFactorPercent,
  double coverageRatio = 1,
}) {
  return HeatingUsage(
    deviceId: 'device-1',
    serial: 'SN-1',
    from: query.from,
    to: query.to,
    bucket: query.bucket?.wireValue ?? '',
    timezone: query.timezone ?? 'UTC',
    availableFrom: query.from,
    coverageRatio: coverageRatio,
    loadFactorPercent: loadFactorPercent,
    minBucketPercent: loadFactorPercent,
    maxBucketPercent: loadFactorPercent,
    points: const [],
  );
}

class _FakeHeatingUsageReader implements HeatingUsageReader {
  const _FakeHeatingUsageReader(this.callback);

  final Future<HeatingUsage> Function(TelemetryUsageQuery query) callback;

  @override
  Future<HeatingUsage> getHeatingUsage({required TelemetryUsageQuery query}) {
    return callback(query);
  }
}
