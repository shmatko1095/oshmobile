import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/platform/flutter_device_time_zone_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/energy_usage_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/heating_usage_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';
import 'package:oshmobile/features/telemetry_history/presentation/adapters/telemetry_usage_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';

void main() {
  test('uses 1h, 1d and 1mo buckets for approved ranges', () async {
    final backend = _FakeUsageBackend();
    final reader = TelemetryUsageSeriesReader(
      energyReader: backend,
      heatingReader: backend,
      timeZoneReader: FlutterDeviceTimeZoneReader(
        identifierLoader: () async => 'Europe/Stockholm',
      ),
    );
    final from = DateTime.utc(2026, 1, 1);

    await reader.getSeries(
      seriesKey: TelemetryHistoryMetricCatalog.energyUsage,
      from: from,
      to: from.add(const Duration(hours: 25)),
    );
    expect(backend.lastEnergyQuery!.bucket?.wireValue, '1h');
    expect(backend.lastEnergyQuery!.timezone, 'Europe/Stockholm');

    await reader.getSeries(
      seriesKey: TelemetryHistoryMetricCatalog.energyUsage,
      from: from,
      to: from.add(const Duration(days: 31)),
    );
    expect(backend.lastEnergyQuery!.bucket?.wireValue, '1d');
    expect(backend.lastEnergyQuery!.timezone, 'Europe/Stockholm');

    await reader.getSeries(
      seriesKey: TelemetryHistoryMetricCatalog.energyUsage,
      from: from,
      to: from.add(const Duration(days: 31, hours: 1)),
    );
    expect(backend.lastEnergyQuery!.bucket?.wireValue, '1d');

    await reader.getSeries(
      seriesKey: TelemetryHistoryMetricCatalog.heatingUsage,
      from: from,
      to: from.add(const Duration(days: 31, hours: 2)),
    );
    expect(backend.lastHeatingQuery!.bucket?.wireValue, '1mo');
    expect(backend.lastHeatingQuery!.timezone, 'Europe/Stockholm');
  });

  test('maps backend summary and null points without client aggregation',
      () async {
    final backend = _FakeUsageBackend();
    final reader = TelemetryUsageSeriesReader(
      energyReader: backend,
      heatingReader: backend,
      timeZoneReader: FlutterDeviceTimeZoneReader(
        identifierLoader: () async => 'Europe/Stockholm',
      ),
    );
    final from = DateTime.utc(2026, 7, 18);
    final series = await reader.getSeries(
      seriesKey: TelemetryHistoryMetricCatalog.energyUsage,
      from: from,
      to: from.add(const Duration(days: 1)),
    );

    expect(series.usageSummary?.total, 4.2);
    expect(series.usageSummary?.average, 0.2);
    expect(series.usageSummary?.peak, 0.8);
    expect(series.points, hasLength(2));
    expect(series.points.last.sumValue, isNull);
    expect(series.points.last.coverageRatio, 0.5);
  });
}

class _FakeUsageBackend implements EnergyUsageReader, HeatingUsageReader {
  TelemetryUsageQuery? lastEnergyQuery;
  TelemetryUsageQuery? lastHeatingQuery;

  @override
  Future<EnergyUsage> getEnergyUsage({
    required TelemetryUsageQuery query,
  }) async {
    lastEnergyQuery = query;
    return EnergyUsage(
      deviceId: 'device-1',
      serial: 'SN-1',
      from: query.from,
      to: query.to,
      bucket: query.bucket?.wireValue ?? '',
      timezone: query.timezone ?? 'UTC',
      availableFrom: query.from,
      coverageRatio: 0.95,
      totalKwh: 4.2,
      averageBucketKwh: 0.2,
      peakBucketKwh: 0.8,
      peakBucketFrom: query.from,
      points: <EnergyUsagePoint>[
        EnergyUsagePoint(
          from: query.from,
          to: query.from.add(const Duration(hours: 1)),
          energyKwh: 0.8,
          coverageRatio: 1,
        ),
        EnergyUsagePoint(
          from: query.from.add(const Duration(hours: 1)),
          to: query.from.add(const Duration(hours: 2)),
          energyKwh: null,
          coverageRatio: 0.5,
        ),
      ],
    );
  }

  @override
  Future<HeatingUsage> getHeatingUsage({
    required TelemetryUsageQuery query,
  }) async {
    lastHeatingQuery = query;
    return HeatingUsage(
      deviceId: 'device-1',
      serial: 'SN-1',
      from: query.from,
      to: query.to,
      bucket: query.bucket?.wireValue ?? '',
      timezone: query.timezone ?? 'UTC',
      availableFrom: query.from,
      coverageRatio: 1,
      loadFactorPercent: 35,
      minBucketPercent: 10,
      maxBucketPercent: 80,
      points: <HeatingUsagePoint>[
        HeatingUsagePoint(
          from: query.from,
          to: query.to,
          loadFactorPercent: 35,
          coverageRatio: 1,
        ),
      ],
    );
  }
}
