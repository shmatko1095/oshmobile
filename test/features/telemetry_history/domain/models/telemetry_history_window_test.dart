import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_retention_policy.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';

void main() {
  test('day uses local midnight and clips current query at now', () {
    final now = DateTime(2026, 7, 17, 14, 32);
    final window = TelemetryHistoryWindow.current(
      range: TelemetryHistoryRange.day,
      nowLocal: now,
    );

    expect(window.startLocal, DateTime(2026, 7, 17));
    expect(window.endLocal, DateTime(2026, 7, 18));
    expect(window.queryFromUtc, DateTime(2026, 7, 17).toUtc());
    expect(window.queryToUtc(now), now.toUtc());
    expect(window.canGoNext(now), isFalse);
  });

  test('week starts on Monday and ends after Sunday', () {
    final window = TelemetryHistoryWindow.containing(
      range: TelemetryHistoryRange.week,
      anchorLocal: DateTime(2026, 7, 17),
    );

    expect(window.startLocal, DateTime(2026, 7, 13));
    expect(window.endLocal, DateTime(2026, 7, 20));
    expect(window.durationDays, 7);
  });

  test('month follows actual calendar length including leap February', () {
    final leap = TelemetryHistoryWindow.containing(
      range: TelemetryHistoryRange.month,
      anchorLocal: DateTime(2024, 2, 20),
    );
    final common = TelemetryHistoryWindow.containing(
      range: TelemetryHistoryRange.month,
      anchorLocal: DateTime(2026, 2, 20),
    );

    expect(leap.startLocal, DateTime(2024, 2));
    expect(leap.endLocal, DateTime(2024, 3));
    expect(leap.durationDays, 29);
    expect(common.durationDays, 28);
  });

  test('year follows leap year and next is blocked for current period', () {
    final now = DateTime(2024, 6, 1);
    final current = TelemetryHistoryWindow.current(
      range: TelemetryHistoryRange.year,
      nowLocal: now,
    );
    final previous = current.previous();

    expect(current.durationDays, 366);
    expect(identical(current.next(now), current), isTrue);
    expect(previous.startLocal, DateTime(2023));
    expect(previous.canGoNext(now), isTrue);
    expect(previous.next(now).startLocal, current.startLocal);
  });

  test('previous navigation stops when the prior period misses retention', () {
    final now = DateTime(2026, 7, 17, 14, 30);
    const retention = Duration(days: 370);
    final earliestTimestamp = now.subtract(retention);
    final earliestDay = DateTime(
      earliestTimestamp.year,
      earliestTimestamp.month,
      earliestTimestamp.day,
    );
    final window = TelemetryHistoryWindow.containing(
      range: TelemetryHistoryRange.day,
      anchorLocal: earliestDay,
    );

    expect(
      TelemetryHistoryRetentionPolicy(
        maxQueryDuration: retention,
      ).canGoPrevious(window, nowLocal: now),
      isFalse,
    );
  });

  test('UTC bounds preserve the actual local calendar boundaries', () {
    final start = DateTime(2026, 3, 29);
    final window = TelemetryHistoryWindow.containing(
      range: TelemetryHistoryRange.day,
      anchorLocal: start,
    );

    expect(window.queryFromUtc, window.startLocal.toUtc());
    expect(
      window.queryToUtc(DateTime(2026, 3, 31)),
      window.endLocal.toUtc(),
    );
    expect(window.durationDays, 1);
  });

  test('custom range normalizes reverse selection and keeps inclusive end', () {
    final window = TelemetryHistoryWindow.custom(
      startLocal: DateTime(2026, 7, 19, 22, 10),
      endInclusiveLocal: DateTime(2026, 7, 13, 8, 45),
    );

    expect(window.range, TelemetryHistoryRange.custom);
    expect(window.startLocal, DateTime(2026, 7, 13));
    expect(window.endLocal, DateTime(2026, 7, 20));
    expect(window.durationDays, 7);
  });

  test('custom single day clips query at now and disables navigation', () {
    final now = DateTime(2026, 7, 17, 14, 32);
    final window = TelemetryHistoryWindow.custom(
      startLocal: now,
      endInclusiveLocal: now,
    );

    expect(window.startLocal, DateTime(2026, 7, 17));
    expect(window.endLocal, DateTime(2026, 7, 18));
    expect(window.queryToUtc(now), now.toUtc());
    expect(window.canGoNext(now), isFalse);
    expect(
      const TelemetryHistoryRetentionPolicy()
          .canGoPrevious(window, nowLocal: now),
      isFalse,
    );
    expect(identical(window.previous(), window), isTrue);
    expect(identical(window.next(now), window), isTrue);
  });

  test('preset factories reject custom range without explicit dates', () {
    expect(
      () => TelemetryHistoryWindow.current(
        range: TelemetryHistoryRange.custom,
        nowLocal: DateTime(2026, 7, 17),
      ),
      throwsArgumentError,
    );
    expect(
      () => TelemetryHistoryWindow.containing(
        range: TelemetryHistoryRange.custom,
        anchorLocal: DateTime(2026, 7, 17),
      ),
      throwsArgumentError,
    );
  });
}
