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

  testWidgets('adds range minimum to tooltip when formatter is provided', (
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
                  values: const <double>[120],
                  displayValues: const <double>[120],
                  rangeMinValues: const <double?>[40],
                  rangeMaxValues: const <double?>[250],
                  timestamps: <DateTime>[start],
                  color: Colors.blue,
                ),
              ],
              tooltipValueFormatter: (_, value) =>
                  '${value.toStringAsFixed(0)} W',
              tooltipMinValueFormatter: (_, value) =>
                  'Minimum: ${value.toStringAsFixed(0)} W',
              showAxes: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final mainBar = chart.data.lineBarsData.first;
    final items = chart.data.lineTouchData.touchTooltipData.getTooltipItems(
      <LineBarSpot>[
        LineBarSpot(
          mainBar,
          0,
          mainBar.spots.first,
        ),
      ],
    );
    final tooltipText =
        items.single!.children!.map((span) => span.text ?? '').join();

    expect(tooltipText, contains('Active power: 120 W'));
    expect(tooltipText, contains('Minimum: 40 W'));
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

  testWidgets('uses configured area fill opacity for filled series', (
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
                  id: 'climate_sensors.air.temp',
                  label: 'Air',
                  values: const <double>[21, 22],
                  timestamps: <DateTime>[
                    start,
                    start.add(const Duration(minutes: 5)),
                  ],
                  color: Colors.orange,
                  fill: true,
                  fillTopAlpha: 0.26,
                  fillBottomAlpha: 0.04,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final area = chart.data.lineBarsData.single.belowBarData;
    final gradient = area.gradient! as LinearGradient;

    expect(area.show, isTrue);
    expect(gradient.colors, <Color>[
      Colors.orange.withValues(alpha: 0.26),
      Colors.orange.withValues(alpha: 0.04),
    ]);
  });

  testWidgets('activity band does not affect y-axis range', (tester) async {
    final start = DateTime.utc(2026, 3, 15, 12, 0, 0);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: HistoryMultiLineChart(
              series: <HistoryMultiLineSeries>[
                HistoryMultiLineSeries(
                  id: 'climate_sensors.air.temp',
                  label: 'Air',
                  values: const <double>[20, 22],
                  timestamps: <DateTime>[
                    start,
                    start.add(const Duration(minutes: 5)),
                  ],
                  color: Colors.blue,
                ),
                HistoryMultiLineSeries(
                  id: 'heating',
                  label: 'Heating',
                  values: const <double>[0, 1],
                  displayValues: const <double>[0, 1],
                  timestamps: <DateTime>[
                    start,
                    start.add(const Duration(minutes: 5)),
                  ],
                  color: Colors.orange,
                  fill: true,
                  includeInYAxisRange: false,
                  activityBand: const HistoryMultiLineActivityBand(),
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
    final heatingBar = chart.data.lineBarsData[1];

    expect(chart.data.minY, 20);
    expect(chart.data.maxY, 22);
    expect(heatingBar.spots.first.y, 20);
    expect(heatingBar.spots.last.y, closeTo(20.36, 0.0001));
  });
}
