import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_chart.dart';

void main() {
  testWidgets('renders min-max band when range values are valid', (
    tester,
  ) async {
    final start = DateTime.utc(2026, 3, 15, 12, 0, 0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: HistoryMultiLineChart(
              series: <HistoryMultiLineSeries>[
                HistoryMultiLineSeries(
                  id: 'power_meter.active_power_w',
                  label: 'Active power',
                  values: const <double>[120, 900],
                  displayValues: const <double>[120, 900],
                  rangeMinValues: const <double?>[40, 80],
                  rangeMaxValues: const <double?>[250, 920],
                  timestamps: <DateTime>[
                    start,
                    start.add(const Duration(minutes: 5)),
                  ],
                  color: Colors.blue,
                ),
              ],
              showAxes: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.betweenBarsData, hasLength(1));
    expect(chart.data.lineBarsData.length, greaterThanOrEqualTo(3));
  });

  testWidgets('does not render min-max band for invalid range points', (
    tester,
  ) async {
    final start = DateTime.utc(2026, 3, 15, 12, 0, 0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: HistoryMultiLineChart(
              series: <HistoryMultiLineSeries>[
                HistoryMultiLineSeries(
                  id: 'power_meter.active_power_w',
                  label: 'Active power',
                  values: const <double>[120, 900],
                  displayValues: const <double>[120, 900],
                  rangeMinValues: const <double?>[300, null],
                  rangeMaxValues: const <double?>[250, 920],
                  timestamps: <DateTime>[
                    start,
                    start.add(const Duration(minutes: 5)),
                  ],
                  color: Colors.blue,
                ),
              ],
              showAxes: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.betweenBarsData, isEmpty);
  });
}
