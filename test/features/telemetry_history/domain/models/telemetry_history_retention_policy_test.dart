import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_retention_policy.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';

void main() {
  const policy = TelemetryHistoryRetentionPolicy();
  final now = DateTime(2026, 7, 18, 19, 30);

  test('normalizes reverse custom dates before validation', () {
    final window = TelemetryHistoryWindow.custom(
      startLocal: DateTime(2026, 7, 17),
      endInclusiveLocal: DateTime(2026, 7, 10),
    );

    expect(window.startLocal, DateTime(2026, 7, 10));
    expect(window.endLocal, DateTime(2026, 7, 18));
    expect(policy.allowsCustomWindow(window, nowLocal: now), isTrue);
  });

  test('accepts one day and rejects future days', () {
    final today = TelemetryHistoryWindow.custom(
      startLocal: DateTime(2026, 7, 18),
      endInclusiveLocal: DateTime(2026, 7, 18),
    );
    final future = TelemetryHistoryWindow.custom(
      startLocal: DateTime(2026, 7, 19),
      endInclusiveLocal: DateTime(2026, 7, 19),
    );

    expect(policy.allowsCustomWindow(today, nowLocal: now), isTrue);
    expect(policy.allowsCustomWindow(future, nowLocal: now), isFalse);
  });

  test('rejects a query whose actual UTC duration exceeds retention', () {
    final tooLong = TelemetryHistoryWindow.custom(
      startLocal: DateTime(2025, 7, 13),
      endInclusiveLocal: DateTime(2026, 7, 18),
    );

    expect(policy.allowsCustomWindow(tooLong, nowLocal: now), isFalse);
  });

  test('earliest available date is normalized to local midnight', () {
    final firstDate = policy.earliestAvailableDay(now);

    expect(firstDate.hour, 0);
    expect(firstDate.minute, 0);
    expect(firstDate, DateTime(2025, 7, 13));
  });
}
