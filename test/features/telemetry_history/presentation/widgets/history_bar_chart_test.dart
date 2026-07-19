import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_bar_chart.dart';

void main() {
  testWidgets('keeps unavailable bucket as a gap and respects reduced motion',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SizedBox(
            width: 360,
            height: 240,
            child: HistoryBarChart(
              values: const <double?>[1, null, 2],
              timestamps: <DateTime>[
                DateTime.utc(2026, 7, 19, 8),
                DateTime.utc(2026, 7, 19, 9),
                DateTime.utc(2026, 7, 19, 10),
              ],
              semanticLabel: 'Energy usage',
            ),
          ),
        ),
      ),
    );

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups, hasLength(3));
    expect(chart.data.barGroups[0].barRods.single.toY, 1);
    expect(chart.data.barGroups[1].barRods.single.toY, 0);
    expect(chart.data.barGroups[2].barRods.single.toY, 2);
    expect(chart.duration, Duration.zero);
    expect(find.bySemanticsLabel('Energy usage'), findsOneWidget);
  });
}
