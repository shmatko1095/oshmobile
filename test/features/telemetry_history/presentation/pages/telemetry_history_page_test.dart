import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
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
  String resolution = '5m',
}) {
  return TelemetryHistorySeries(
    deviceId: 'd',
    serial: 'sn',
    seriesKey: seriesKey,
    resolution: resolution,
    from: from,
    to: to,
    points: points,
  );
}

List<TelemetryHistoryMetric> _numberedMetrics(int count) {
  return List<TelemetryHistoryMetric>.generate(count, (index) {
    final number = index + 1;
    return TelemetryHistoryMetric(
      title: 'Metric $number',
      subtitle: 'Label $number',
      seriesKey: 'metric.$number',
      kind: TelemetryHistoryMetricKind.numeric,
      unit: 'W',
    );
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  TelemetryHistoryCubit cubit, {
  String? initialSeriesKey,
  String title = 'History',
}) async {
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
        child: TelemetryHistoryPage(
          title: title,
          initialSeriesKey: initialSeriesKey,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('TelemetryHistoryPage', () {
    testWidgets('renders temperature sensors in one carousel', (tester) async {
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

      expect(find.text('History'), findsOneWidget);
      expect(find.text('Temperature'), findsWidgets);
      expect(find.text('Air'), findsOneWidget);
      expect(find.text('Floor', skipOffstage: false), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('telemetry-history-dashboard-scroll')),
        findsOneWidget,
      );
      expect(find.byType(PageView), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('telemetry-history-temperature-carousel'),
        ),
        findsOneWidget,
      );
      expect(find.text('1 / 2'), findsOneWidget);
      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.pinned, isTrue);
      expect(appBar.bottom, isNull);
      expect(find.byType(PinnedHeaderSliver), findsOneWidget);

      final nextTemperature = find.byKey(
        const ValueKey('telemetry-history-temperature-next'),
      );
      expect(tester.widget<IconButton>(nextTemperature).onPressed, isNotNull);
      await tester.fling(
        find.byKey(
          const ValueKey('telemetry-history-temperature-carousel'),
        ),
        const Offset(-500, 0),
        1200,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('2 / 2'), findsOneWidget);
      expect(cubit.state.metric.seriesKey, 'climate_sensors.floor.temp');

      await cubit.close();
    });

    testWidgets('opens the temperature carousel on the requested sensor',
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
        initialMetricIndex: 1,
      );

      await _pumpPage(tester, cubit);
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      final carousel = tester.widget<PageView>(
        find.byKey(
          const ValueKey('telemetry-history-temperature-carousel'),
        ),
      );
      expect(carousel.controller?.page, 1);

      await cubit.close();
    });

    testWidgets('calendar arrows navigate without changing range',
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

      final currentStart = cubit.state.window.startLocal;
      final nextButton = find.byKey(
        const ValueKey('telemetry-history-period-next'),
      );
      expect(tester.widget<IconButton>(nextButton).onPressed, isNull);

      await tester.tap(
        find.byKey(const ValueKey('telemetry-history-period-previous')),
      );
      await tester.pump();

      expect(cubit.state.range, TelemetryHistoryRange.day);
      expect(
        cubit.state.window.startLocal,
        currentStart.subtract(const Duration(days: 1)),
      );
      expect(api.requests, hasLength(2));
      expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);

      await cubit.close();
    });

    testWidgets('disables previous period outside archive retention',
        (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime(2026, 7, 17, 14, 30);
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
        initialRange: TelemetryHistoryRange.year,
        nowLocal: () => now,
      );

      await _pumpPage(tester, cubit);
      final previousButton = find.byKey(
        const ValueKey('telemetry-history-period-previous'),
      );
      expect(
        tester.widget<IconButton>(previousButton).onPressed,
        isNotNull,
      );

      await tester.tap(previousButton);
      await tester.pump();

      expect(cubit.state.window.startLocal, DateTime(2025));
      expect(api.requests, hasLength(1));
      expect(tester.widget<IconButton>(previousButton).onPressed, isNull);
      api.requests.single.completer.complete(
        _series(
          seriesKey: api.requests.single.seriesKey,
          from: api.requests.single.from,
          to: api.requests.single.to,
          points: const <TelemetryHistoryPoint>[],
          resolution: '24h',
        ),
      );
      await tester.pumpAndSettle();

      await cubit.close();
    });

    testWidgets('date row opens range sheet and clear restores preset header',
        (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime(2026, 7, 17, 14, 30);
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
        initialMetricIndex: 1,
        nowLocal: () => now,
      );
      final presetWindow = cubit.state.window;

      await _pumpPage(
        tester,
        cubit,
        initialSeriesKey: 'climate_sensors.floor.temp',
      );
      expect(find.text('2 / 2'), findsOneWidget);
      await tester.pumpAndSettle();
      final periodHeader = find.byKey(
        const ValueKey('telemetry-history-period-header'),
      );
      final presetHeaderHeight = tester.getSize(periodHeader).height;
      expect(presetHeaderHeight, greaterThan(100));
      await tester.tap(
        find.byKey(
          const ValueKey('telemetry-history-period-open-calendar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('telemetry-history-date-range-sheet')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('telemetry-history-date-range-apply')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(cubit.state.range, TelemetryHistoryRange.custom);
      expect(
        find.byKey(const ValueKey('telemetry-history-custom-range-clear')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('telemetry-history-range-selector')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('telemetry-history-period-previous')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('telemetry-history-period-next')),
        findsNothing,
      );
      expect(find.text('2 / 2'), findsOneWidget);
      expect(cubit.state.metric.seriesKey, 'climate_sensors.floor.temp');
      final customHeaderHeight = tester.getSize(periodHeader).height;
      expect(customHeaderHeight, lessThan(80));
      expect(customHeaderHeight, lessThan(presetHeaderHeight - 40));
      expect(api.requests, hasLength(2));
      for (final request in api.requests) {
        request.completer.complete(
          _series(
            seriesKey: request.seriesKey,
            from: request.from,
            to: request.to,
            points: const <TelemetryHistoryPoint>[],
          ),
        );
      }
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('telemetry-history-custom-range-clear')),
      );
      await tester.pump();

      expect(cubit.state.range, TelemetryHistoryRange.day);
      expect(cubit.state.window.startLocal, presetWindow.startLocal);
      expect(cubit.state.window.endLocal, presetWindow.endLocal);
      expect(find.text('2 / 2'), findsOneWidget);
      expect(api.requests, hasLength(4));
      for (final request in api.requests.skip(2)) {
        request.completer.complete(
          _series(
            seriesKey: request.seriesKey,
            from: request.from,
            to: request.to,
            points: const <TelemetryHistoryPoint>[],
          ),
        );
      }
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('telemetry-history-range-selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('telemetry-history-period-previous')),
        findsOneWidget,
      );
      expect(
        tester.getSize(periodHeader).height,
        closeTo(presetHeaderHeight, 0.5),
      );

      await cubit.close();
    });

    testWidgets('scrolls to the requested initial sensor anchor',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: _numberedMetrics(12),
        nowUtc: () => now,
      );

      await _pumpPage(
        tester,
        cubit,
        initialSeriesKey: 'metric.10',
      );
      await tester.pumpAndSettle();

      final targetLabelFinder = find.text('Label 10');
      expect(targetLabelFinder, findsOneWidget);
      final targetRect = tester.getRect(targetLabelFinder);
      expect(targetRect.top, greaterThanOrEqualTo(150));
      expect(targetRect.bottom, lessThanOrEqualTo(640));
      expect(tester.getRect(find.text('Label 1')).bottom, lessThan(150));

      await cubit.close();
    });

    testWidgets('custom range reload preserves dashboard scroll offset',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime(2026, 7, 17, 14, 30);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: _numberedMetrics(12),
        nowLocal: () => now,
      );

      await _pumpPage(tester, cubit);
      final scrollFinder = find.byKey(
        const ValueKey('telemetry-history-dashboard-scroll'),
      );
      final periodHeader = find.byKey(
        const ValueKey('telemetry-history-period-header'),
      );
      final initialHeaderTop = tester.getTopLeft(periodHeader).dy;
      await tester.drag(scrollFinder, const Offset(0, -700));
      await tester.pump();
      final scrollView = tester.widget<CustomScrollView>(scrollFinder);
      final initialOffset = scrollView.controller!.offset;
      expect(initialOffset, greaterThan(0));
      expect(
        tester.getTopLeft(periodHeader).dy,
        closeTo(initialHeaderTop, 0.5),
      );

      final rangeFuture = cubit.selectCustomRange(
        startLocal: DateTime(2026, 7, 10),
        endInclusiveLocal: DateTime(2026, 7, 17),
      );
      await tester.pump();

      expect(cubit.state.range, TelemetryHistoryRange.custom);
      expect(scrollView.controller!.offset, closeTo(initialOffset, 0.5));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.getSize(periodHeader).height, lessThan(80));
      expect(
        tester.getTopLeft(periodHeader).dy,
        closeTo(initialHeaderTop, 0.5),
      );
      expect(scrollView.controller!.offset, closeTo(initialOffset, 0.5));
      expect(api.requests, hasLength(12));
      for (final request in api.requests) {
        request.completer.complete(
          _series(
            seriesKey: request.seriesKey,
            from: request.from,
            to: request.to,
            points: const <TelemetryHistoryPoint>[],
          ),
        );
      }
      expect(await rangeFuture, isTrue);
      await tester.pump();
      expect(scrollView.controller!.offset, closeTo(initialOffset, 0.5));

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

    testWidgets('does not label history returned at reduced resolution',
        (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime(2026, 7, 17, 14, 30);
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
        nowLocal: () => now,
      );

      await _pumpPage(tester, cubit);
      cubit.load();
      await tester.pump();
      final request = api.requests.single;
      request.completer.complete(
        _series(
          seriesKey: request.seriesKey,
          from: request.from,
          to: request.to,
          resolution: '30m',
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: request.from,
              samplesCount: 2,
              minValue: 20,
              maxValue: 22,
              avgValue: 21,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('telemetry-history-resolution-30m')),
        findsNothing,
      );
      expect(find.byType(HistoryMultiLineChart), findsOneWidget);

      await cubit.close();
    });

    testWidgets('keeps graph errors independent and retries only failed graph',
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
          ),
        ],
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);
      unawaited(cubit.load());
      await tester.pump();
      expect(api.requests, hasLength(2));

      final voltage = api.requests.firstWhere(
        (request) => request.seriesKey == 'power_meter.voltage_v',
      );
      final current = api.requests.firstWhere(
        (request) => request.seriesKey == 'power_meter.current_a',
      );
      voltage.completer.completeError(Exception('voltage unavailable'));
      current.completer.complete(
        _series(
          seriesKey: current.seriesKey,
          from: current.from,
          to: current.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: current.from,
              samplesCount: 1,
              avgValue: 2.4,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to load'), findsOneWidget);
      expect(find.byType(HistoryMultiLineChart), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(api.requests, hasLength(3));
      expect(api.requests.last.seriesKey, 'power_meter.voltage_v');

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
      expect(api.requests, hasLength(3));
      for (final request in api.requests) {
        final value = switch (request.seriesKey) {
          'power_meter.voltage_v' => 229.74,
          'power_meter.current_a' => 4.256,
          _ => 512.54,
        };
        request.completer.complete(
          _series(
            seriesKey: request.seriesKey,
            from: request.from,
            to: request.to,
            points: <TelemetryHistoryPoint>[
              TelemetryHistoryPoint(
                bucketStart: request.from,
                samplesCount: 1,
                avgValue: value,
                minValue: value,
                maxValue: value,
              ),
            ],
          ),
        );
      }
      await tester.pumpAndSettle();

      expect(find.text('4.26 A'), findsNWidgets(3));
      expect(find.text('229.7 V'), findsNWidgets(3));
      expect(find.text('512.5 W'), findsNWidgets(3));
      expect(find.byType(HistoryMultiLineChart), findsNWidgets(3));

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
      expect(chart.series.single.points.single.value, 900.0);
      expect(chart.series.single.points.single.rangeMinValue, 40.0);
      expect(chart.series.single.points.single.rangeMaxValue, 900.0);
      expect(
        chart.tooltipTimeLabelBuilder!(api.requests.single.from),
        contains(':'),
      );

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
      expect(chart.color, AppPalette.accentSuccess);
      expect(
        chart.tooltipTimeLabelBuilder!(api.requests.single.from),
        contains(':'),
      );
      expect(chart.showGrid, isTrue);
      expect(chart.showHorizontalGrid, isNull);
      expect(chart.showVerticalGrid, isFalse);
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
      final chart = tester.widget<HistoryBarChart>(
        find.byType(HistoryBarChart),
      );
      expect(
        chart.tooltipTimeLabelBuilder!(api.requests.single.from),
        isNot(contains(':')),
      );
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Avg / day'), findsOneWidget);
      expect(find.text('Peak interval'), findsOneWidget);
      expect(find.text('Daily avg'), findsNothing);
      expect(find.text('1.000 kWh'), findsOneWidget);
      expect(find.text('0.143 kWh'), findsOneWidget);
      expect(find.text('0.580 kWh'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('uses heating red for heating usage bars', (tester) async {
      final api = _QueuedTelemetryHistoryApi();
      final now = DateTime.utc(2026, 3, 14, 20, 18, 40);
      final cubit = TelemetryHistoryCubit(
        seriesReader: api,
        metrics: const <TelemetryHistoryMetric>[
          TelemetryHistoryMetric(
            title: 'Heating runtime',
            seriesKey: 'usage.heating',
            kind: TelemetryHistoryMetricKind.numeric,
            unit: '%',
            fractionDigits: 0,
            displayMode: TelemetryHistoryMetricDisplayMode.heatingUsage,
          ),
        ],
        nowUtc: () => now,
      );

      await _pumpPage(tester, cubit);

      cubit.load();
      await tester.pump();
      api.requests.single.completer.complete(
        _series(
          seriesKey: api.requests.single.seriesKey,
          from: api.requests.single.from,
          to: api.requests.single.to,
          points: <TelemetryHistoryPoint>[
            TelemetryHistoryPoint(
              bucketStart: api.requests.single.from,
              samplesCount: 1,
              lastNumericValue: 35,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final chart = tester.widget<HistoryBarChart>(
        find.byType(HistoryBarChart),
      );
      expect(chart.color, AppPalette.accentWarning);

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

      final chart = tester.widget<HistoryLineChart>(
        find.byType(HistoryLineChart),
      );
      expect(
        chart.tooltipBuilder!(api.requests.single.from, 1),
        contains(':'),
      );
      expect(find.byType(HistoryMultiLineChart), findsNothing);

      await cubit.close();
    });
  });
}
