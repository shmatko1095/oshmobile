import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_chart_gap_resolver.dart';

void main() {
  test('returns threshold based on median delta', () {
    final start = DateTime.utc(2026, 3, 15, 12, 0, 0);
    final timestamps = <DateTime?>[
      start,
      start.add(const Duration(minutes: 5)),
      start.add(const Duration(minutes: 10)),
      start.add(const Duration(minutes: 30)),
    ];

    final threshold =
        HistoryChartGapResolver.resolveGapThresholdSeconds(timestamps);

    expect(threshold, 750); // 5 minutes * 2.5
  });

  test('secondsBetween returns null for non-positive interval', () {
    final at = DateTime.utc(2026, 3, 15, 12, 0, 0);

    expect(HistoryChartGapResolver.secondsBetween(at, at), isNull);
    expect(
        HistoryChartGapResolver.secondsBetween(
            at, at.subtract(const Duration(seconds: 1))),
        isNull);
  });
}
