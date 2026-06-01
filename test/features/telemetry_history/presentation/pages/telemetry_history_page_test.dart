import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/presentation/pages/telemetry_history_page.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_bar_chart.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_line_chart.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_chart.dart';
import 'package:oshmobile/generated/l10n.dart';

class _Request {
  _Request({
    required this.seriesKey,
    required this.from,
    required this.to,
    required this.completer,
  });

  final String seriesKey;
  final DateTime from;
  final DateTime to;
  final Completer<TelemetryHistorySeries> completer;
}

class _QueuedTelemetryHistoryApi implements TelemetryHistorySeriesReader {
  final List<_Request> requests = <_Request>[];

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) {
    final completer = Completer<TelemetryHistorySeries>();
    requests.add(
      _Request(
        seriesKey: seriesKey,
        from: from,
        to: to,
        completer: completer,
      ),
    );
    return completer.future;
  }
}

TelemetryHistorySeries _series({
  required String seriesKey,
  required DateTime from,
  required DateTime to,
  required List<TelemetryHistoryPoint> points,
}) {
  return TelemetryHistorySeries(
    deviceId: 'd',
    serial: 'sn',
    seriesKey: seriesKey,
    resolution: '5m',
    from: from,
    to: to,
    points: points,
  );
}

Future<void> _pumpPage(
  WidgetTester tester,
  TelemetryHistoryCubit cubit,
) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: BlocProvider<TelemetryHistoryCubit>.value(
        value: cubit,
        child: const TelemetryHistoryPage(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('TelemetryHistoryPage', () {
    testWidgets('renders app bar, metric selector and range selector',
        (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Temperature',
            subtitle: 'Air',
            seriesKey: 'climate_sensors.air.temp',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: '°C',
          ),
          TelemetryHistoryMetric(
            title: 'Temperature',
            subtitle: 'Floor',
            seriesKey: 'climate_sensors.floor.temp',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: '°C',
          ),
        ],
      );

      await _pumpPage(tester, cubit);

      expect(find.text('Temperature'), findsOneWidget);
      expect(find.text('Air'), findsOneWidget);
      expect(find.text('Floor'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('updates selected metric on page swipe and chip tap',
        (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Temperature',
            subtitle: 'Air',
            seriesKey: 'climate_sensors.air.temp',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: '°C',
          ),
          TelemetryHistoryMetric(
            title: 'Temperature',
            subtitle: 'Floor',
            seriesKey: 'climate_sensors.floor.temp',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: '°C',
          ),
        ],
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cubit.state.selectedMetricIndex, 1);
      expect(api.requests, hasLength(1));
      expect(api.requests.last.seriesKey, 'climate_sensors.floor.temp');

      api.requests.last.completer.complete(
        _series(
          seriesKey: api.requests.last.seriesKey,
          from: api.requests.last.from,
          to: api.requests.last.to,
          points: const <TelemetryHistoryPoint>[],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Air'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cubit.state.selectedMetricIndex, 0);
      expect(api.requests, hasLength(2));
      expect(api.requests.last.seriesKey, 'climate_sensors.air.temp');

      await cubit.close();
    });

    testWidgets('updates selected range on range tap', (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Temperature',
            subtitle: 'Air',
            seriesKey: 'climate_sensors.air.temp',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: '°C',
          ),
        ],
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);

      cubit.load();
      await tester.pump();
      expect(api.requests, hasLength(1));

      api.requests.last.completer.complete(
        _series(
          seriesKey: api.requests.last.seriesKey,
          from: api.requests.last.from,
          to: api.requests.last.to,
          points: const <TelemetryHistoryPoint>[],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Week'));
      await tester.pump();

      expect(cubit.state.range, TelemetryHistoryRange.week);
      expect(api.requests, hasLength(2));

      await cubit.close();
    });

    testWidgets('shows loading, error, empty and data states', (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Temperature',
            subtitle: 'Air',
            seriesKey: 'climate_sensors.air.temp',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: '°C',
          ),
        ],
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);

      cubit.load();
      await tester.pump();
      await tester.pump();
      expect(cubit.state.isLoading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(api.requests, hasLength(1));

      api.requests.last.completer.completeError(Exception('network failed'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Failed to load'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(api.requests, hasLength(2));

      api.requests.last.completer.complete(
        _series(
          seriesKey: api.requests.last.seriesKey,
          from: api.requests.last.from,
          to: api.requests.last.to,
          points: const <TelemetryHistoryPoint>[],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('No data yet'), findsOneWidget);

      cubit.refresh();
      await tester.pump();
      expect(api.requests, hasLength(3));

      api.requests.last.completer.complete(
        _series(
          seriesKey: api.requests.last.seriesKey,
          from: api.requests.last.from,
          to: api.requests.last.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: api.requests.last.from,
              samplesCount: 1,
              avgValue: 27.0,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HistoryMultiLineChart), findsOneWidget);

      await cubit.close();
    });

    testWidgets('formats power meter metrics with configured precision',
        (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Voltage',
            seriesKey: 'power_meter.voltage_v',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: 'V',
          ),
          TelemetryHistoryMetric(
            title: 'Current',
            seriesKey: 'power_meter.current_a',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: 'A',
            fractionDigits: 2,
          ),
          TelemetryHistoryMetric(
            title: 'Active power',
            seriesKey: 'power_meter.active_power_w',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: 'W',
          ),
        ],
        initialMetricIndex: 1,
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);

      cubit.load();
      await tester.pump();
      expect(api.requests, hasLength(1));
      expect(api.requests.single.seriesKey, 'power_meter.current_a');

      api.requests.single.completer.complete(
        _series(
          seriesKey: api.requests.single.seriesKey,
          from: api.requests.single.from,
          to: api.requests.single.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: api.requests.single.from,
              samplesCount: 1,
              avgValue: 4.256,
              minValue: 4.256,
              maxValue: 4.256,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4.26 A'), findsNWidgets(3));

      await tester.tap(find.text('Voltage'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(api.requests, hasLength(2));

      api.requests.last.completer.complete(
        _series(
          seriesKey: api.requests.last.seriesKey,
          from: api.requests.last.from,
          to: api.requests.last.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: api.requests.last.from,
              samplesCount: 1,
              avgValue: 229.74,
              minValue: 229.74,
              maxValue: 229.74,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('229.7 V'), findsNWidgets(3));

      await tester.tap(find.text('Active power'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(api.requests, hasLength(3));

      api.requests.last.completer.complete(
        _series(
          seriesKey: api.requests.last.seriesKey,
          from: api.requests.last.from,
          to: api.requests.last.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: api.requests.last.from,
              samplesCount: 1,
              avgValue: 512.54,
              minValue: 512.54,
              maxValue: 512.54,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('512.5 W'), findsNWidgets(3));

      await cubit.close();
    });

    testWidgets('renders numeric line from max bucket value', (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Active power',
            seriesKey: 'power_meter.active_power_w',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: 'W',
          ),
        ],
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);

      cubit.load();
      await tester.pump();
      expect(api.requests, hasLength(1));

      api.requests.single.completer.complete(
        _series(
          seriesKey: api.requests.single.seriesKey,
          from: api.requests.single.from,
          to: api.requests.single.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: api.requests.single.from,
              samplesCount: 5,
              avgValue: 120.0,
              minValue: 40.0,
              maxValue: 900.0,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final chart = tester.widget<HistoryMultiLineChart>(
        find.byType(HistoryMultiLineChart),
      );
      expect(chart.series, hasLength(1));
      expect(chart.series.single.values.single, 900.0);
      expect(chart.series.single.rangeMinValues?.single, 40.0);
      expect(chart.series.single.rangeMaxValues?.single, 900.0);

      await cubit.close();
    });

    testWidgets('renders energy metric as bucket bars and total summary',
        (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Energy used',
            seriesKey: 'power_meter.energy_wh_delta',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: 'kWh',
            fractionDigits: 3,
            useSumValue: true,
            valueMultiplier: 0.001,
            displayMode: TelemetryHistoryMetricDisplayMode.energyDelta,
          ),
        ],
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);

      cubit.load();
      await tester.pump();
      expect(api.requests, hasLength(1));

      api.requests.single.completer.complete(
        _series(
          seriesKey: api.requests.single.seriesKey,
          from: api.requests.single.from,
          to: api.requests.single.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: api.requests.single.from,
              samplesCount: 5,
              sumValue: 420.0,
              avgValue: 10.0,
              minValue: 5.0,
              maxValue: 900.0,
            ),
            TelemetryHistoryPoint(
              bucketStart: api.requests.single.from.add(
                const Duration(minutes: 5),
              ),
              samplesCount: 5,
              sumValue: 580.0,
              avgValue: 20.0,
              minValue: 10.0,
              maxValue: 1000.0,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HistoryMultiLineChart), findsNothing);
      final chart = tester.widget<HistoryBarChart>(
        find.byType(HistoryBarChart),
      );
      expect(chart.values, <double>[0.42, 0.58]);
      expect(chart.showGrid, isFalse);
      expect(chart.showHorizontalGrid, isNull);
      expect(chart.showVerticalGrid, isNull);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Avg / hour'), findsOneWidget);
      expect(find.text('Peak interval'), findsOneWidget);
      expect(find.text('Daily avg'), findsNothing);
      expect(find.text('Peak bucket'), findsNothing);
      expect(find.text('1.000 kWh'), findsOneWidget);
      expect(find.text('0.042 kWh'), findsOneWidget);
      expect(find.text('0.580 kWh'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows daily energy average for week range', (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Energy used',
            seriesKey: 'power_meter.energy_wh_delta',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: 'kWh',
            fractionDigits: 3,
            useSumValue: true,
            valueMultiplier: 0.001,
            displayMode: TelemetryHistoryMetricDisplayMode.energyDelta,
          ),
        ],
        initialRange: TelemetryHistoryRange.week,
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);

      cubit.load();
      await tester.pump();
      expect(api.requests, hasLength(1));

      api.requests.single.completer.complete(
        _series(
          seriesKey: api.requests.single.seriesKey,
          from: api.requests.single.from,
          to: api.requests.single.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: api.requests.single.from,
              samplesCount: 5,
              sumValue: 420.0,
            ),
            TelemetryHistoryPoint(
              bucketStart: api.requests.single.from.add(
                const Duration(hours: 12),
              ),
              samplesCount: 5,
              sumValue: 580.0,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HistoryBarChart), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Avg / day'), findsOneWidget);
      expect(find.text('Peak interval'), findsOneWidget);
      expect(find.text('Daily avg'), findsNothing);
      expect(find.text('1.000 kWh'), findsOneWidget);
      expect(find.text('0.143 kWh'), findsOneWidget);
      expect(find.text('0.580 kWh'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('keeps boolean metrics on single-line chart', (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Heating activity',
            seriesKey: 'heater_enabled',
            kind: TelemetryHistoryMetricKind.boolean,
          ),
        ],
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);

      cubit.load();
      await tester.pump();
      expect(api.requests, hasLength(1));

      api.requests.single.completer.complete(
        _series(
          seriesKey: api.requests.single.seriesKey,
          from: api.requests.single.from,
          to: api.requests.single.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: api.requests.single.from,
              samplesCount: 4,
              trueRatio: 0.5,
              lastBoolValue: true,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HistoryLineChart), findsOneWidget);
      expect(find.byType(HistoryMultiLineChart), findsNothing);

      await cubit.close();
    });
  });
}
