import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/data/shared_preferences_temperature_history_preview_cache.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/temperature_history_preview_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('writes and reads preview records', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = SharedPreferencesTemperatureHistoryPreviewCache(prefs);
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);

    await cache.write(
      namespace: 'device/sn',
      seriesKey: 'climate_sensors.floor.temp',
      record: TemperatureHistoryPreviewCacheRecord(
        values: const <double>[21.1, 21.5],
        timestamps: <DateTime>[
          now.subtract(const Duration(minutes: 10)),
          now,
        ],
        savedAt: now,
        windowStart: now.subtract(const Duration(hours: 24)),
        windowEnd: now,
      ),
    );

    final record = await cache.read(
      namespace: 'device/sn',
      seriesKey: 'climate_sensors.floor.temp',
      nowUtc: now,
      maxAge: const Duration(days: 7),
    );

    expect(record, isNotNull);
    expect(record!.values, const <double>[21.1, 21.5]);
    expect(record.timestamps, <DateTime>[
      now.subtract(const Duration(minutes: 10)),
      now,
    ]);
    expect(record.windowStart, now.subtract(const Duration(hours: 24)));
    expect(record.windowEnd, now);
  });

  test('drops expired preview records', () async {
    final prefs = await SharedPreferences.getInstance();
    final cache = SharedPreferencesTemperatureHistoryPreviewCache(prefs);
    final now = DateTime.utc(2026, 3, 14, 20, 18, 40);

    await cache.write(
      namespace: 'device-sn',
      seriesKey: 'climate_sensors.floor.temp',
      record: TemperatureHistoryPreviewCacheRecord(
        values: const <double>[21.1],
        timestamps: <DateTime>[now.subtract(const Duration(days: 8))],
        savedAt: now.subtract(const Duration(days: 8)),
        windowStart: now.subtract(const Duration(days: 9)),
        windowEnd: now.subtract(const Duration(days: 8)),
      ),
    );

    final record = await cache.read(
      namespace: 'device-sn',
      seriesKey: 'climate_sensors.floor.temp',
      nowUtc: now,
      maxAge: const Duration(days: 7),
    );

    expect(record, isNull);
  });
}
