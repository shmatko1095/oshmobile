import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/configuration/models/model_configuration.dart';
import 'package:oshmobile/features/devices/details/data/configuration_thermostat_dashboard_schema_builder.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/adapters/thermostat_telemetry_history_opener.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/thermostat_presenters.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_history_strip_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';
import 'package:oshmobile/features/telemetry_history/presentation/pages/telemetry_history_page.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  test(
      'visibleWidgetIds includes power meter widgets when controls are readable',
      () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
        {
          'id': 'apparentPowerNow',
          'control_ids': [
            'powerMeterApparentPowerVa',
            'powerMeterApparentPowerValid',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
        {
          'id': 'powerMeterVoltageValid',
          'path': 'power_meter.voltage_valid',
        },
        {'id': 'powerMeterCurrentA', 'path': 'power_meter.current_a'},
        {
          'id': 'powerMeterCurrentValid',
          'path': 'power_meter.current_valid',
        },
        {
          'id': 'powerMeterApparentPowerVa',
          'path': 'power_meter.apparent_power_va',
        },
        {
          'id': 'powerMeterApparentPowerValid',
          'path': 'power_meter.apparent_power_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );

    expect(
      _schema(bundle).visibleWidgetIds,
      containsAllInOrder(
        const <String>['voltageNow', 'currentNow', 'apparentPowerNow'],
      ),
    );
  });

  test('visibleWidgetIds includes energy widget when telemetry is readable',
      () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'energyUsed',
          'control_ids': <String>[],
        },
      ],
      controls: const <Map<String, dynamic>>[],
      readableDomains: const <String>{'telemetry'},
    );

    expect(
      _schema(bundle).visibleWidgetIds,
      contains('energyUsed'),
    );
  });

  test(
      'visibleWidgetIds hides power meter widget when value control is missing',
      () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'voltageNow',
          'control_ids': ['missingVoltage', 'powerMeterVoltageValid'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {
          'id': 'powerMeterVoltageValid',
          'path': 'power_meter.voltage_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );

    expect(
      _schema(bundle).visibleWidgetIds,
      isNot(contains('voltageNow')),
    );
  });

  test('visibleWidgetIds hides power meter widget without control ids', () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'voltageNow',
          'control_ids': <String>[],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
      ],
      readableDomains: const <String>{'telemetry'},
    );

    expect(
      _schema(bundle).visibleWidgetIds,
      isNot(contains('voltageNow')),
    );
  });

  test('visibleWidgetIds hides power meter widget when telemetry is unreadable',
      () {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterCurrentA', 'path': 'power_meter.current_a'},
        {
          'id': 'powerMeterCurrentValid',
          'path': 'power_meter.current_valid',
        },
      ],
      readableDomains: const <String>{},
    );

    expect(
      _schema(bundle).visibleWidgetIds,
      isNot(contains('currentNow')),
    );
  });

  testWidgets('temperature history preview is embedded in hero card',
      (tester) async {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'heroTemperature',
          'control_ids': [
            'ambientTemperature',
            'scheduleCurrentTarget',
            'scheduleNextTarget',
            'climateSensors',
          ],
        },
        {
          'id': 'modeBar',
          'control_ids': ['scheduleMode'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'ambientTemperature', 'path': 'ambient.temperature'},
        {'id': 'scheduleCurrentTarget', 'path': 'schedule.current_target'},
        {'id': 'scheduleNextTarget', 'path': 'schedule.next_target'},
        {'id': 'climateSensors', 'path': 'climateSensors'},
        {'id': 'scheduleMode', 'path': 'schedule.mode'},
      ],
      readableDomains: const <String>{'telemetry'},
    );
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: DeviceSlice<Map<String, dynamic>>.ready(
        data: const <String, dynamic>{
          'ambientTemperature': 22.1,
          'scheduleCurrentTarget': 22,
          'scheduleNextTarget': {
            'temp': 21,
            'hour': 20,
            'minute': 30,
          },
          'scheduleMode': 'manual',
          'climateSensors': [
            {
              'id': 'air',
              'name': 'Air',
              'ref': true,
              'temp_valid': true,
              'temp_stale': false,
              'temp': 22.1,
              'humidity_valid': false,
            },
          ],
        },
      ),
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final snapshotCubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(snapshotCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: Builder(
            builder: (context) {
              return _presenter().build(context, _device(), bundle);
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TemperatureMinimalPanel), findsOneWidget);
    expect(find.byType(TemperatureHistoryStripCard), findsNothing);
    expect(find.byType(ThermostatModeBar), findsOneWidget);
    expect(
      find.byKey(const ValueKey('temperature-history-preview-air')),
      findsOneWidget,
    );

    final heroTop = tester.getTopLeft(find.byType(TemperatureMinimalPanel)).dy;
    final modeTop = tester.getTopLeft(find.byType(ThermostatModeBar)).dy;
    expect(heroTop, lessThan(modeTop));
  });

  testWidgets('power meter tiles open history with tapped metric selected',
      (tester) async {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
        {
          'id': 'apparentPowerNow',
          'control_ids': [
            'powerMeterApparentPowerVa',
            'powerMeterApparentPowerValid',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
        {
          'id': 'powerMeterVoltageValid',
          'path': 'power_meter.voltage_valid',
        },
        {'id': 'powerMeterCurrentA', 'path': 'power_meter.current_a'},
        {
          'id': 'powerMeterCurrentValid',
          'path': 'power_meter.current_valid',
        },
        {
          'id': 'powerMeterApparentPowerVa',
          'path': 'power_meter.apparent_power_va',
        },
        {
          'id': 'powerMeterApparentPowerValid',
          'path': 'power_meter.apparent_power_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: DeviceSlice<Map<String, dynamic>>.ready(
        data: const <String, dynamic>{
          'powerMeterVoltageV': 230,
          'powerMeterVoltageValid': true,
          'powerMeterCurrentA': 4.2,
          'powerMeterCurrentValid': true,
          'powerMeterApparentPowerVa': 966,
          'powerMeterApparentPowerValid': true,
        },
      ),
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final snapshotCubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(snapshotCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: Builder(
            builder: (context) {
              return _presenter().build(context, _device(), bundle);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Current'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TelemetryHistoryPage), findsOneWidget);
    expect(history.requests, hasLength(1));
    expect(
      history.requests.single.seriesKey,
      TelemetryHistoryMetricCatalog.powerMeterCurrentA,
    );
  });

  testWidgets('power now tile opens history with active power selected',
      (tester) async {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'powerNow',
          'control_ids': [
            'powerMeterActivePowerW',
            'powerMeterActivePowerValid'
          ],
        },
        {
          'id': 'apparentPowerNow',
          'control_ids': [
            'powerMeterApparentPowerVa',
            'powerMeterApparentPowerValid',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {
          'id': 'powerMeterActivePowerW',
          'path': 'power_meter.active_power_w',
        },
        {
          'id': 'powerMeterActivePowerValid',
          'path': 'power_meter.active_power_valid',
        },
        {
          'id': 'powerMeterApparentPowerVa',
          'path': 'power_meter.apparent_power_va',
        },
        {
          'id': 'powerMeterApparentPowerValid',
          'path': 'power_meter.apparent_power_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: DeviceSlice<Map<String, dynamic>>.ready(
        data: const <String, dynamic>{
          'powerMeterActivePowerW': 942,
          'powerMeterActivePowerValid': true,
          'powerMeterApparentPowerVa': 966,
          'powerMeterApparentPowerValid': true,
        },
      ),
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final snapshotCubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(snapshotCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: Builder(
            builder: (context) {
              return _presenter().build(context, _device(), bundle);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Power'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TelemetryHistoryPage), findsOneWidget);
    final pageContext = tester.element(find.byType(TelemetryHistoryPage));
    final historyCubit = pageContext.read<TelemetryHistoryCubit>();
    final historySeriesKeys =
        historyCubit.state.metrics.map((metric) => metric.seriesKey).toList();
    expect(
      historySeriesKeys,
      equals(
        const <String>[
          TelemetryHistoryMetricCatalog.powerMeterActivePowerW,
        ],
      ),
    );
    expect(history.requests, hasLength(1));
    expect(
      history.requests.single.seriesKey,
      TelemetryHistoryMetricCatalog.powerMeterActivePowerW,
    );
  });

  testWidgets(
      'apparent power tile opens history with apparent power metric selected',
      (tester) async {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
        {
          'id': 'apparentPowerNow',
          'control_ids': [
            'powerMeterApparentPowerVa',
            'powerMeterApparentPowerValid',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
        {
          'id': 'powerMeterVoltageValid',
          'path': 'power_meter.voltage_valid',
        },
        {'id': 'powerMeterCurrentA', 'path': 'power_meter.current_a'},
        {
          'id': 'powerMeterCurrentValid',
          'path': 'power_meter.current_valid',
        },
        {
          'id': 'powerMeterApparentPowerVa',
          'path': 'power_meter.apparent_power_va',
        },
        {
          'id': 'powerMeterApparentPowerValid',
          'path': 'power_meter.apparent_power_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: DeviceSlice<Map<String, dynamic>>.ready(
        data: const <String, dynamic>{
          'powerMeterVoltageV': 230,
          'powerMeterVoltageValid': true,
          'powerMeterCurrentA': 4.2,
          'powerMeterCurrentValid': true,
          'powerMeterApparentPowerVa': 966,
          'powerMeterApparentPowerValid': true,
        },
      ),
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final snapshotCubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(snapshotCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: Builder(
            builder: (context) {
              return _presenter().build(context, _device(), bundle);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apparent power'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TelemetryHistoryPage), findsOneWidget);
    final pageContext = tester.element(find.byType(TelemetryHistoryPage));
    final historyCubit = pageContext.read<TelemetryHistoryCubit>();
    final historySeriesKeys =
        historyCubit.state.metrics.map((metric) => metric.seriesKey).toList();
    expect(
      historySeriesKeys,
      equals(
        const <String>[
          TelemetryHistoryMetricCatalog.powerMeterApparentPowerVa,
        ],
      ),
    );
    expect(history.requests, hasLength(1));
    expect(
      history.requests.single.seriesKey,
      TelemetryHistoryMetricCatalog.powerMeterApparentPowerVa,
    );
  });

  testWidgets('energy tile opens energy history metric', (tester) async {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'energyUsed',
          'control_ids': <String>[],
        },
        {
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
        {
          'id': 'powerMeterVoltageValid',
          'path': 'power_meter.voltage_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: DeviceSlice<Map<String, dynamic>>.ready(
        data: const <String, dynamic>{
          'powerMeterVoltageV': 230,
          'powerMeterVoltageValid': true,
        },
      ),
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final snapshotCubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(snapshotCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: Builder(
            builder: (context) {
              return _presenter().build(context, _device(), bundle);
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(history.aggregateRequests, hasLength(1));
    expect(
      history.aggregateRequests.single.query.seriesKeys,
      const <String>[TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta],
    );
    expect(find.text('—'), findsOneWidget);
    expect(find.text('— kWh'), findsNothing);
    history.aggregateRequests.single.completer.complete(
      _aggregate(
        from: history.aggregateRequests.single.query.from,
        to: history.aggregateRequests.single.query.to,
        energyWh: 1234,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1.23 kWh'), findsOneWidget);

    await tester.tap(find.text('Energy used'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TelemetryHistoryPage), findsOneWidget);
    final pageContext = tester.element(find.byType(TelemetryHistoryPage));
    final historyCubit = pageContext.read<TelemetryHistoryCubit>();
    final historySeriesKeys =
        historyCubit.state.metrics.map((metric) => metric.seriesKey).toList();
    expect(
      historySeriesKeys,
      equals(
        const <String>[
          TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta,
        ],
      ),
    );
    expect(history.requests, hasLength(1));
    expect(
      history.requests.single.seriesKey,
      TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta,
    );
  });

  testWidgets('voltage tile opens only voltage history metric', (tester) async {
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'energyUsed',
          'control_ids': <String>[],
        },
        {
          'id': 'powerNow',
          'control_ids': [
            'powerMeterActivePowerW',
            'powerMeterActivePowerValid'
          ],
        },
        {
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {
          'id': 'powerMeterActivePowerW',
          'path': 'power_meter.active_power_w',
        },
        {
          'id': 'powerMeterActivePowerValid',
          'path': 'power_meter.active_power_valid',
        },
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
        {
          'id': 'powerMeterVoltageValid',
          'path': 'power_meter.voltage_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: DeviceSlice<Map<String, dynamic>>.ready(
        data: const <String, dynamic>{
          'powerMeterActivePowerW': 942,
          'powerMeterActivePowerValid': true,
          'powerMeterVoltageV': 230,
          'powerMeterVoltageValid': true,
        },
      ),
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final snapshotCubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(snapshotCubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: Builder(
            builder: (context) {
              return _presenter().build(context, _device(), bundle);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voltage'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TelemetryHistoryPage), findsOneWidget);
    final pageContext = tester.element(find.byType(TelemetryHistoryPage));
    final historyCubit = pageContext.read<TelemetryHistoryCubit>();
    final historySeriesKeys =
        historyCubit.state.metrics.map((metric) => metric.seriesKey).toList();
    expect(
      historySeriesKeys,
      equals(
        const <String>[
          TelemetryHistoryMetricCatalog.powerMeterVoltageV,
        ],
      ),
    );
    expect(history.requests, hasLength(1));
    expect(
      history.requests.single.seriesKey,
      TelemetryHistoryMetricCatalog.powerMeterVoltageV,
    );
  });
}

ThermostatBasicPresenter _presenter() {
  return ThermostatBasicPresenter(
    schemaBuilder: const ConfigurationThermostatDashboardSchemaBuilder(),
    historyOpener: const ThermostatTelemetryHistoryOpener(),
  );
}

ThermostatDashboardSchema _schema(DeviceConfigurationBundle bundle) {
  return const ConfigurationThermostatDashboardSchemaBuilder()
      .build(bundle: bundle);
}

DeviceConfigurationBundle _bundle({
  required List<Map<String, dynamic>> widgets,
  required List<Map<String, dynamic>> controls,
  required Set<String> readableDomains,
}) {
  return DeviceConfigurationBundle(
    configurationId: 'configuration-1',
    modelId: 'model-1',
    revision: 1,
    status: 'approved',
    firmwareVersion: '0.60.0',
    runtimeContractsByDomain: const <String, RuntimeContractRecord>{},
    runtimeContractsById: const <String, RuntimeContractRecord>{},
    readableDomains: readableDomains,
    patchableDomains: const <String>{},
    configuration: ModelConfiguration.fromJson(
      <String, dynamic>{
        'schema_version': 1,
        'integrations': {
          'oshmobile': {
            'layout': 'thermostat_basic',
            'domains': {
              'telemetry': {'contract_id': 'telemetry@1'},
            },
            'widgets': widgets,
            'controls': [
              for (final control in controls)
                {
                  'id': control['id'],
                  'title': control['id'],
                  'read': {
                    'kind': 'domain_path',
                    'domain': 'telemetry',
                    'path': control['path'],
                  },
                },
            ],
          },
        },
      },
    ),
  );
}

Device _device() {
  return Device(
    id: 'device-1',
    sn: 'SN-1',
    modelId: 'model',
    modelName: 'Model',
    userData: const DeviceUserData(alias: 'Device', description: ''),
    connectionInfo: ConnectionInfo(online: true),
  );
}

TelemetryAggregate _aggregate({
  required DateTime from,
  required DateTime to,
  required double energyWh,
}) {
  return TelemetryAggregate(
    deviceId: 'device-1',
    serial: 'SN-1',
    resolution: '5m',
    from: from,
    to: to,
    series: <TelemetryAggregateSeries>[
      TelemetryAggregateSeries(
        seriesKey: TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta,
        valueType: 'numeric',
        unit: 'Wh',
        samplesCount: 24,
        sumValue: energyWh,
      ),
    ],
  );
}

final class _QueuedTelemetryHistoryApi implements DeviceTelemetryHistoryApi {
  final List<_Request> requests = <_Request>[];
  final List<_AggregateRequest> aggregateRequests = <_AggregateRequest>[];

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) {
    final completer = Completer<TelemetryHistorySeries>();
    requests.add(_Request(seriesKey: seriesKey, completer: completer));
    return completer.future;
  }

  @override
  Future<TelemetryAggregate> getAggregate({
    required TelemetryAggregateQuery query,
  }) {
    final completer = Completer<TelemetryAggregate>();
    aggregateRequests.add(
      _AggregateRequest(query: query, completer: completer),
    );
    return completer.future;
  }
}

final class _Request {
  const _Request({
    required this.seriesKey,
    required this.completer,
  });

  final String seriesKey;
  final Completer<TelemetryHistorySeries> completer;
}

final class _AggregateRequest {
  const _AggregateRequest({
    required this.query,
    required this.completer,
  });

  final TelemetryAggregateQuery query;
  final Completer<TelemetryAggregate> completer;
}

final class _FakeDeviceFacade implements DeviceFacade {
  const _FakeDeviceFacade(this._snapshot, this._history);

  final DeviceSnapshot _snapshot;
  final DeviceTelemetryHistoryApi _history;

  @override
  DeviceSnapshot get current => _snapshot;

  @override
  Stream<DeviceSnapshot> watch() => const Stream<DeviceSnapshot>.empty();

  @override
  DeviceTelemetryHistoryApi get telemetryHistory => _history;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
