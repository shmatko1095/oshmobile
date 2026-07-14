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
                  points: _points(
                    values: const <double>[120, 900],
                    rangeMinValues: const <double?>[40, 80],
                    rangeMaxValues: const <double?>[250, 920],
                    start: start,
                  ),
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
                  points: _points(
                    values: const <double>[120],
                    rangeMinValues: const <double?>[40],
                    rangeMaxValues: const <double?>[250],
                    start: start,
                  ),
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
                  points: _points(
                    values: const <double>[120, 900],
                    rangeMinValues: const <double?>[300, null],
                    rangeMaxValues: const <double?>[250, 920],
                    start: start,
                  ),
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
                  points: _points(
                    values: const <double>[21, 22],
                    start: start,
                  ),
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
                  points: _points(
                    values: const <double>[20, 22],
                    start: start,
                  ),
                  color: Colors.blue,
                ),
                HistoryMultiLineSeries(
                  id: 'heating',
                  label: 'Heating',
                  points: _points(
                    values: const <double>[0, 1],
                    start: start,
                  ),
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

  testWidgets(
    'replaces the chart when the visible series topology changes',
    (tester) async {
      final start = DateTime.utc(2026, 3, 15, 12, 0, 0);
      final temperature = HistoryMultiLineSeries(
        id: 'climate_sensors.air.temp',
        label: 'Air',
        points: _points(
          values: const <double>[20, 22],
          start: start,
        ),
        color: Colors.blue,
      );
      final heating = HistoryMultiLineSeries(
        id: 'heating',
        label: 'Heating',
        points: _points(
          values: const <double>[0, 1],
          start: start,
        ),
        color: Colors.orange,
        includeInYAxisRange: false,
        activityBand: const HistoryMultiLineActivityBand(),
      );

      Widget buildChart(List<HistoryMultiLineSeries> series) {
        return MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(child: HistoryMultiLineChart(series: series)),
          ),
        );
      }

      await tester
          .pumpWidget(buildChart(<HistoryMultiLineSeries>[temperature]));
      await tester.pump();
      final originalElement = tester.element(find.byType(LineChart));
      final originalKey = tester.widget<LineChart>(find.byType(LineChart)).key;

      await tester.pumpWidget(
        buildChart(<HistoryMultiLineSeries>[temperature, heating]),
      );
      await tester.pump();
      final changedElement = tester.element(find.byType(LineChart));
      final changedKey = tester.widget<LineChart>(find.byType(LineChart)).key;

      expect(changedElement, isNot(same(originalElement)));
      expect(changedKey, isNot(originalKey));
    },
  );

  testWidgets('keeps the chart for a data-only update', (tester) async {
    final start = DateTime.utc(2026, 3, 15, 12, 0, 0);

    Widget buildChart(List<double> values) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: HistoryMultiLineChart(
              series: <HistoryMultiLineSeries>[
                HistoryMultiLineSeries(
                  id: 'climate_sensors.air.temp',
                  label: 'Air',
                  points: _points(values: values, start: start),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildChart(const <double>[20, 22]));
    await tester.pump();
    final originalElement = tester.element(find.byType(LineChart));

    await tester.pumpWidget(buildChart(const <double>[21, 23]));
    await tester.pump();

    expect(tester.element(find.byType(LineChart)), same(originalElement));
  });

  testWidgets('tooltip includes overlays only from the anchor bucket', (
    tester,
  ) async {
    final start = DateTime.utc(2026, 3, 15, 12);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(
            child: HistoryMultiLineChart(
              tooltipAnchorSeriesId: 'temperature',
              series: <HistoryMultiLineSeries>[
                HistoryMultiLineSeries(
                  id: 'temperature',
                  label: 'Temperature',
                  points: <HistoryMultiLinePoint>[
                    HistoryMultiLinePoint(
                      timestamp: start,
                      value: 21,
                      displayValue: 21,
                    ),
                  ],
                  color: Colors.blue,
                ),
                HistoryMultiLineSeries(
                  id: 'target',
                  label: 'Target',
                  points: <HistoryMultiLinePoint>[
                    HistoryMultiLinePoint(
                      timestamp: start.add(const Duration(minutes: 5)),
                      value: 41,
                      tooltipText: 'ON',
                    ),
                  ],
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final items = chart.data.lineTouchData.touchTooltipData.getTooltipItems(
      <LineBarSpot>[
        LineBarSpot(
          chart.data.lineBarsData[0],
          0,
          chart.data.lineBarsData[0].spots.first,
        ),
        LineBarSpot(
          chart.data.lineBarsData[1],
          1,
          chart.data.lineBarsData[1].spots.first,
        ),
      ],
    );
    final text = items
        .whereType<LineTooltipItem>()
        .expand((item) => item.children ?? const <TextSpan>[])
        .map((span) => span.text ?? '')
        .join();

    expect(text, contains('Temperature'));
    expect(text, isNot(contains('Target')));
    expect(text, isNot(contains('ON')));
  });
}

List<HistoryMultiLinePoint> _points({
  required List<double> values,
  required DateTime start,
  List<double?>? rangeMinValues,
  List<double?>? rangeMaxValues,
}) {
  return List<HistoryMultiLinePoint>.generate(
    values.length,
    (index) => HistoryMultiLinePoint(
      timestamp: start.add(Duration(minutes: index * 5)),
      value: values[index],
      displayValue: values[index],
      rangeMinValue: rangeMinValues?[index],
      rangeMaxValue: rangeMaxValues?[index],
    ),
    growable: false,
  );
}
