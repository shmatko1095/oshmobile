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
import 'package:oshmobile/features/devices/details/presentation/presenters/device_presenter_chrome.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/thermostat_presenters.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_history_strip_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_dashboard_app_bar.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/daily_stats_24h_card.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';
import 'package:oshmobile/features/telemetry_history/data/shared_preferences_daily_energy_usage_cache.dart';
import 'package:oshmobile/features/telemetry_history/data/shared_preferences_temperature_history_preview_cache.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';
import 'package:oshmobile/features/telemetry_history/presentation/pages/telemetry_history_page.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/coordination/user_guide_host_registry.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../user_guide/test_user_guide_progress_repository.dart';

late SharedPreferences _sharedPreferences;
late UserGuideCubit _defaultUserGuideCubit;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    _sharedPreferences = await SharedPreferences.getInstance();
    _defaultUserGuideCubit = UserGuideCubit(
      repository: TestUserGuideProgressRepository(
        completedTopics: const <UserGuideTopic>{
          UserGuideTopic.thermostatLiveMetricsV1,
        },
      ),
    );
    await _defaultUserGuideCubit.load();
    addTearDown(_defaultUserGuideCubit.close);
  });

  test('thermostat presenter uses its embedded app bar', () {
    expect(_presenter().usesEmbeddedAppBar, isTrue);
  });

  testWidgets('dashboard app bar stays pinned without collapsed temperature',
      (tester) async {
    var drawerOpened = false;
    var settingsOpened = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              ThermostatDashboardAppBar(
                roomName: 'Living Room',
                chrome: DevicePresenterChrome(
                  onOpenDrawer: () => drawerOpened = true,
                  onOpenSettings: () => settingsOpened = true,
                  activityIndicator: const SizedBox.shrink(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 1000)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(find.text('Living Room'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('thermostat-open-drawer')),
    );
    await tester.tap(
      find.byKey(const ValueKey('thermostat-open-settings')),
    );
    expect(drawerOpened, isTrue);
    expect(settingsOpened, isTrue);

    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -520),
    );
    await tester.pumpAndSettle();

    expect(find.text('Living Room'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('thermostat-collapsed-temperature-opacity')),
      findsNothing,
    );
  });

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

  testWidgets('configured daily stats render as one non-interactive card',
      (tester) async {
    final userGuideCubit = UserGuideCubit(
      repository: TestUserGuideProgressRepository(),
    );
    await userGuideCubit.load();
    addTearDown(userGuideCubit.close);
    final bundle = _bundle(
      widgets: const <Map<String, dynamic>>[
        {
          'id': 'dailyStats24h',
          'control_ids': [
            'powerMeterEnergyWhDelta',
            'heatingActivity24h',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {
          'id': 'powerMeterEnergyWhDelta',
          'path': 'power_meter.energy_wh_delta',
        },
        {'id': 'heatingActivity24h', 'path': 'load_factor'},
      ],
      readableDomains: const <String>{'telemetry'},
    );
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: DeviceSlice<Map<String, dynamic>>.ready(
        data: const <String, dynamic>{
          'heatingActivity24h': 55,
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
          child: _buildPresenter(
            _device(),
            bundle,
            userGuideCubit: userGuideCubit,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(DailyStats24hCard), findsOneWidget);
    expect(find.text('Last 24 hours'), findsOneWidget);
    expect(find.text('Energy used'), findsOneWidget);
    expect(find.text('Heating runtime'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget);
    expect(history.aggregateRequests, hasLength(1));
    expect(
      history.aggregateRequests.single.query.seriesKeys,
      const <String>[TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta],
    );

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
    expect(find.byType(TelemetryHistoryPage), findsNothing);
    expect(history.requests, isEmpty);
    expect(
      find.byKey(const ValueKey('thermostat-live-metrics-handle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsNothing,
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
      history: const <String, dynamic>{
        'series': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'temperature',
            'path': 'climate_sensors.*.temp',
            'value_type': 'number',
          },
        ],
        'views': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'temperature',
            'series_ids': <String>['temperature'],
          },
        ],
      },
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
          child: _buildPresenter(_device(), bundle),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TemperatureMinimalPanel), findsOneWidget);
    expect(
      find.byKey(const ValueKey('thermostat-dashboard-app-bar')),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byType(TemperatureMinimalPanel),
        matching: find.byType(SliverAppBar),
      ),
      findsNothing,
    );
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

  testWidgets(
      'live metrics show history action opens configured dashboard and returns',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'ambientTemperature', 'path': 'ambient.temperature'},
        {'id': 'scheduleCurrentTarget', 'path': 'schedule.current_target'},
        {'id': 'scheduleNextTarget', 'path': 'schedule.next_target'},
        {'id': 'climateSensors', 'path': 'climateSensors'},
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
        {'id': 'powerMeterVoltageValid', 'path': 'power_meter.voltage_valid'},
      ],
      readableDomains: const <String>{'telemetry'},
      history: const <String, dynamic>{
        'series': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'temperature',
            'path': 'climate_sensors.*.temp',
            'value_type': 'number',
            'unit': 'C',
          },
          <String, dynamic>{
            'id': 'voltage',
            'path': 'power_meter.voltage_v',
            'value_type': 'number',
            'unit': 'V',
          },
        ],
        'views': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'temperature',
            'series_ids': <String>['temperature'],
          },
          <String, dynamic>{
            'id': 'voltage',
            'series_ids': <String>['voltage'],
          },
        ],
      },
    );
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: DeviceSlice<Map<String, dynamic>>.ready(
        data: const <String, dynamic>{
          'ambientTemperature': 22.1,
          'scheduleCurrentTarget': 22,
          'scheduleNextTarget': null,
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
          child: _buildPresenter(_device(), bundle),
        ),
      ),
    );
    await tester.pump();

    await _openLiveMetrics(tester);

    final action = find.byKey(
      const ValueKey('thermostat-live-metrics-show-history'),
    );
    expect(action, findsOneWidget);
    expect(find.text('Show history'), findsOneWidget);
    final actionRect = tester.getRect(action);
    final scrollRect = tester.getRect(
      find.byKey(const ValueKey('thermostat-live-metrics-scroll')),
    );
    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('thermostat-live-metrics-sheet')),
    );
    expect(actionRect.top, greaterThan(scrollRect.top));
    expect(actionRect.bottom, lessThanOrEqualTo(sheetRect.bottom));

    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TelemetryHistoryPage), findsOneWidget);
    final historyContext = tester.element(find.byType(TelemetryHistoryPage));
    final historyCubit = historyContext.read<TelemetryHistoryCubit>();
    expect(
      historyCubit.state.metrics.map((metric) => metric.seriesKey),
      equals(
        const <String>[
          'climate_sensors.air.temp',
          TelemetryHistoryMetricCatalog.powerMeterVoltageV,
        ],
      ),
    );

    Navigator.of(historyContext).pop();
    await tester.pumpAndSettle();

    expect(action, findsOneWidget);
    final liveSheet = tester.widget<DraggableScrollableSheet>(
      find.byKey(const ValueKey('thermostat-live-metrics-draggable-sheet')),
    );
    expect(liveSheet.controller?.size, closeTo(1, 0.001));
  });

  testWidgets(
      'dashboard hides live tiles and sheet preserves configured tile order',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
          'id': 'dailyStats24h',
          'control_ids': [
            'powerMeterEnergyWhDelta',
            'heatingActivity24h',
          ],
        },
        {
          'id': 'modeBar',
          'control_ids': ['scheduleMode'],
        },
        {
          'id': 'heatingToggle',
          'control_ids': ['heaterEnabled'],
        },
        {
          'id': 'voltageNow',
          'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
        },
        {
          'id': 'currentNow',
          'control_ids': ['powerMeterCurrentA', 'powerMeterCurrentValid'],
        },
        {
          'id': 'powerNow',
          'control_ids': [
            'powerMeterActivePowerW',
            'powerMeterActivePowerValid',
          ],
        },
      ],
      controls: const <Map<String, dynamic>>[
        {'id': 'ambientTemperature', 'path': 'ambient.temperature'},
        {'id': 'scheduleCurrentTarget', 'path': 'schedule.current_target'},
        {'id': 'scheduleNextTarget', 'path': 'schedule.next_target'},
        {'id': 'climateSensors', 'path': 'climateSensors'},
        {'id': 'powerMeterEnergyWhDelta', 'path': 'energy_wh_delta'},
        {'id': 'heatingActivity24h', 'path': 'load_factor'},
        {'id': 'scheduleMode', 'path': 'schedule.mode'},
        {'id': 'heaterEnabled', 'path': 'heater.enabled'},
        {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
        {'id': 'powerMeterVoltageValid', 'path': 'power_meter.voltage_valid'},
        {'id': 'powerMeterCurrentA', 'path': 'power_meter.current_a'},
        {'id': 'powerMeterCurrentValid', 'path': 'power_meter.current_valid'},
        {
          'id': 'powerMeterActivePowerW',
          'path': 'power_meter.active_power_w',
        },
        {
          'id': 'powerMeterActivePowerValid',
          'path': 'power_meter.active_power_valid',
        },
      ],
      readableDomains: const <String>{'telemetry'},
    );
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: DeviceSlice<Map<String, dynamic>>.ready(
        data: const <String, dynamic>{
          'ambientTemperature': 22.1,
          'scheduleCurrentTarget': 22,
          'scheduleNextTarget': null,
          'climateSensors': [
            {
              'id': 'air',
              'name': 'Air',
              'ref': true,
              'temp_valid': true,
              'temp_stale': false,
              'temp': 22.1,
              'humidity_valid': true,
              'humidity': 43,
            },
          ],
          'heatingActivity24h': 0.55,
          'scheduleMode': 'off',
          'heaterEnabled': false,
          'powerMeterVoltageV': 230,
          'powerMeterVoltageValid': true,
          'powerMeterCurrentA': 4.2,
          'powerMeterCurrentValid': true,
          'powerMeterActivePowerW': 942,
          'powerMeterActivePowerValid': true,
        },
      ),
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final snapshotCubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(snapshotCubit.close);
    final userGuideCubit = UserGuideCubit(
      repository: TestUserGuideProgressRepository(),
    );
    await userGuideCubit.load();
    addTearDown(userGuideCubit.close);

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
          child: _buildPresenter(
            _device(),
            bundle,
            userGuideCubit: userGuideCubit,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TemperatureMinimalPanel), findsOneWidget);
    expect(
      tester
          .widget<TemperatureMinimalPanel>(find.byType(TemperatureMinimalPanel))
          .heatingStatusBind,
      'heaterEnabled',
    );
    expect(find.byType(DailyStats24hCard), findsOneWidget);
    expect(find.byType(ThermostatModeBar), findsOneWidget);
    expect(
      find.byKey(const ValueKey('thermostat-live-metrics-handle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('user-guide-live-metrics-coach')),
      findsOneWidget,
    );
    expect(find.text('Voltage'), findsNothing);

    final dashboardScrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byKey(const ValueKey('thermostat-dashboard-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(dashboardScrollable.position.maxScrollExtent, 0);

    await _openLiveMetrics(tester);

    expect(
      userGuideCubit.state.isCompleted(
        UserGuideTopic.thermostatLiveMetricsV1,
      ),
      isFalse,
    );

    final heatingOffset = tester.getTopLeft(find.text('Heating'));
    final voltageOffset = tester.getTopLeft(find.text('Voltage'));
    final currentOffset = tester.getTopLeft(find.text('Current'));
    final powerOffset = tester.getTopLeft(find.text('Power'));
    expect(heatingOffset.dy, closeTo(voltageOffset.dy, 1));
    expect(heatingOffset.dx, lessThan(voltageOffset.dx));
    expect(currentOffset.dy, greaterThan(heatingOffset.dy));
    expect(currentOffset.dy, closeTo(powerOffset.dy, 1));
    expect(currentOffset.dx, lessThan(powerOffset.dx));

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('thermostat-live-metrics-sheet')),
    );
    expect(sheetRect.top, closeTo(0, 0.1));
    expect(sheetRect.bottom, closeTo(800, 0.1));
  });

  testWidgets('dashboard adapts without overflow in compact and landscape',
      (tester) async {
    final cases = <({Size size, double textScale})>[
      (size: const Size(320, 568), textScale: 1),
      (size: const Size(800, 400), textScale: 1),
      (size: const Size(400, 800), textScale: 2),
    ];

    for (final testCase in cases) {
      await tester.binding.setSurfaceSize(testCase.size);
      final history = _QueuedTelemetryHistoryApi();
      final snapshot = _adaptiveDashboardSnapshot();
      final facade = _FakeDeviceFacade(snapshot, history);
      final snapshotCubit = DeviceSnapshotCubit(facade: facade);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(testCase.textScale),
            ),
            child: child!,
          ),
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
            child: _buildPresenter(_device(), _adaptiveDashboardBundle()),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'size=${testCase.size}, textScale=${testCase.textScale}',
      );
      expect(find.byType(TemperatureMinimalPanel), findsOneWidget);
      expect(find.byType(DailyStats24hCard), findsOneWidget);
      expect(find.byType(ThermostatModeBar), findsOneWidget);
      if (testCase.size.width > testCase.size.height) {
        expect(
          tester
              .widget<TemperatureMinimalPanel>(
                find.byType(TemperatureMinimalPanel),
              )
              .ultraCompact,
          isTrue,
        );
      } else {
        final heroRect = tester.getRect(
          find.byType(TemperatureMinimalPanel),
        );
        final statsRect = tester.getRect(find.byType(DailyStats24hCard));
        expect(heroRect.left, closeTo(0, 0.1));
        expect(heroRect.right, closeTo(testCase.size.width, 0.1));
        expect(statsRect.left, greaterThanOrEqualTo(20));
        expect(statsRect.right, lessThanOrEqualTo(testCase.size.width - 20));
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await snapshotCubit.close();
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('automatic user guide targets the real mode bar and temperature',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final history = _QueuedTelemetryHistoryApi();
    final snapshot = _adaptiveDashboardSnapshot();
    final facade = _FakeDeviceFacade(snapshot, history);
    final snapshotCubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(snapshotCubit.close);
    final userGuideCubit = UserGuideCubit(
      repository: TestUserGuideProgressRepository(),
    );
    await userGuideCubit.load();
    addTearDown(userGuideCubit.close);

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
          child: _buildPresenter(
            _device(),
            _adaptiveDashboardBundle().copyWith(
              patchableDomains: const <String>{'schedule'},
            ),
            userGuideCubit: userGuideCubit,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(userGuideCubit.state.isAutomaticSessionActive, isTrue);
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('user-guide-next')));
    await tester.pumpAndSettle();

    expect(find.text('Configure an operating mode'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    final modeBarRect = tester.getRect(find.byType(ThermostatModeBar));
    final highlightRect = tester.getRect(
      find.byKey(const ValueKey('user-guide-target-highlight')),
    );
    expect(highlightRect.overlaps(modeBarRect), isTrue);

    await tester.tap(find.byKey(const ValueKey('user-guide-next')));
    await tester.pumpAndSettle();

    expect(find.text('Quick settings'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
    final temperatureRect =
        tester.getRect(find.byType(TemperatureMinimalPanel));
    final temperatureHighlightRect = tester.getRect(
      find.byKey(const ValueKey('user-guide-target-highlight')),
    );
    expect(temperatureHighlightRect.overlaps(temperatureRect), isTrue);
    expect(tester.takeException(), isNull);
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
          child: _buildPresenter(_device(), bundle),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openLiveMetrics(tester);
    expect(
      find.byKey(const ValueKey('thermostat-live-metrics-show-history')),
      findsNothing,
    );
    await tester.tap(find.text('Current'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TelemetryHistoryPage), findsOneWidget);
    expect(history.requests, hasLength(1));
    expect(
      history.requests.single.seriesKey,
      TelemetryHistoryMetricCatalog.powerMeterCurrentA,
    );

    final historyPageContext = tester.element(
      find.byType(TelemetryHistoryPage),
    );
    Navigator.of(historyPageContext).pop();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('thermostat-live-metrics-sheet')),
      findsOneWidget,
    );
    expect(find.text('Current'), findsOneWidget);
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
          child: _buildPresenter(_device(), bundle),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openLiveMetrics(tester);
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
          child: _buildPresenter(_device(), bundle),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openLiveMetrics(tester);
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
          child: _buildPresenter(_device(), bundle),
        ),
      ),
    );
    await tester.pump();
    await _openLiveMetrics(tester);

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
          child: _buildPresenter(_device(), bundle),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openLiveMetrics(tester);
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

Future<void> _openLiveMetrics(WidgetTester tester) async {
  final guide = find.byKey(
    const ValueKey('user-guide-live-metrics-coach'),
  );
  final gestureTarget = guide.evaluate().isNotEmpty
      ? guide
      : find.byKey(const ValueKey('thermostat-dashboard-scroll'));
  await tester.timedDrag(
    gestureTarget,
    const Offset(0, -72),
    const Duration(milliseconds: 500),
  );
  await tester.pumpAndSettle();
  expect(
    find.byKey(const ValueKey('thermostat-live-metrics-sheet')),
    findsOneWidget,
  );
}

ThermostatBasicPresenter _presenter() {
  return ThermostatBasicPresenter(
    schemaBuilder: const ConfigurationThermostatDashboardSchemaBuilder(),
    historyOpener: const ThermostatTelemetryHistoryOpener(),
    historyPreviewCache:
        SharedPreferencesTemperatureHistoryPreviewCache(_sharedPreferences),
    dailyEnergyCache:
        SharedPreferencesDailyEnergyUsageCache(_sharedPreferences),
  );
}

Widget _buildPresenter(
  Device device,
  DeviceConfigurationBundle bundle, {
  UserGuideCubit? userGuideCubit,
}) {
  return RepositoryProvider<UserGuideHostRegistry>.value(
    value: UserGuideHostRegistry(),
    child: BlocProvider<UserGuideCubit>.value(
      value: userGuideCubit ?? _defaultUserGuideCubit,
      child: Builder(
        builder: (context) => _presenter().build(context, device, bundle),
      ),
    ),
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
  Map<String, dynamic>? history,
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
          if (history != null) 'history': history,
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

DeviceConfigurationBundle _adaptiveDashboardBundle() {
  return _bundle(
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
        'id': 'dailyStats24h',
        'control_ids': [
          'powerMeterEnergyWhDelta',
          'heatingActivity24h',
        ],
      },
      {
        'id': 'modeBar',
        'control_ids': ['scheduleMode'],
      },
      {
        'id': 'voltageNow',
        'control_ids': ['powerMeterVoltageV', 'powerMeterVoltageValid'],
      },
    ],
    controls: const <Map<String, dynamic>>[
      {'id': 'ambientTemperature', 'path': 'ambient.temperature'},
      {'id': 'scheduleCurrentTarget', 'path': 'schedule.current_target'},
      {'id': 'scheduleNextTarget', 'path': 'schedule.next_target'},
      {'id': 'climateSensors', 'path': 'climateSensors'},
      {'id': 'powerMeterEnergyWhDelta', 'path': 'energy_wh_delta'},
      {'id': 'heatingActivity24h', 'path': 'load_factor'},
      {'id': 'scheduleMode', 'path': 'schedule.mode'},
      {'id': 'powerMeterVoltageV', 'path': 'power_meter.voltage_v'},
      {'id': 'powerMeterVoltageValid', 'path': 'power_meter.voltage_valid'},
    ],
    readableDomains: const <String>{'telemetry'},
  );
}

DeviceSnapshot _adaptiveDashboardSnapshot() {
  return DeviceSnapshot.initial(device: _device()).copyWith(
    controlState: DeviceSlice<Map<String, dynamic>>.ready(
      data: const <String, dynamic>{
        'ambientTemperature': 22.1,
        'scheduleCurrentTarget': 22,
        'scheduleNextTarget': {
          'temp': 21,
          'hour': 20,
          'minute': 30,
        },
        'climateSensors': [
          {
            'id': 'air',
            'name': 'Air',
            'ref': true,
            'temp_valid': true,
            'temp_stale': false,
            'temp': 22.1,
            'humidity_valid': true,
            'humidity': 43,
          },
        ],
        'heatingActivity24h': 0.55,
        'scheduleMode': 'off',
        'powerMeterVoltageV': 230,
        'powerMeterVoltageValid': true,
      },
    ),
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

  @override
  Future<TelemetrySetpointHistory> getSetpointHistory({
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
  }) {
    throw UnsupportedError('Setpoint history is not used by these tests');
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
