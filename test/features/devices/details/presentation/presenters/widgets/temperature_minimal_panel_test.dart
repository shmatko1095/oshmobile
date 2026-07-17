import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_history_strip_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('shows stale temperature with amber marker', (tester) async {
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: const DeviceSlice<Map<String, dynamic>>.ready(
        data: {
          'climateSensors': [
            {
              'id': 'air',
              'name': 'Air',
              'ref': true,
              'kind': 'air',
              'temp_valid': false,
              'temp_stale': true,
              'temp': 21.4,
              'humidity_valid': false,
            },
          ],
        },
      ),
    );
    final cubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(snapshot),
    );
    addTearDown(cubit.close);

    await _pumpPanel(tester, cubit);

    expect(find.text('21.4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('temperature-stale-indicator-air')),
      findsOneWidget,
    );
    expect(find.text('No temperature data'), findsNothing);
  });

  testWidgets('shows temperature placeholder when sensor temperature is absent',
      (tester) async {
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: const DeviceSlice<Map<String, dynamic>>.ready(
        data: {
          'climateSensors': [
            {
              'id': 'air',
              'name': 'Air',
              'ref': true,
              'kind': 'air',
              'temp_valid': false,
              'temp_stale': false,
              'humidity_valid': false,
            },
          ],
        },
      ),
    );
    final cubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(snapshot),
    );
    addTearDown(cubit.close);

    await _pumpPanel(tester, cubit);

    expect(find.text('--'), findsOneWidget);
    expect(find.text('°C'), findsOneWidget);
    expect(find.text('No sensor data'), findsNothing);
  });

  testWidgets('shows humidity as a secondary reading below temperature',
      (tester) async {
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: const DeviceSlice<Map<String, dynamic>>.ready(
        data: {
          'climateSensors': [
            {
              'id': 'air',
              'name': 'Air',
              'ref': true,
              'kind': 'air',
              'temp_valid': true,
              'temp_stale': false,
              'temp': 21.4,
              'humidity_valid': true,
              'humidity': 48,
            },
          ],
        },
      ),
    );
    final cubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(snapshot),
    );
    addTearDown(cubit.close);

    await _pumpPanel(tester, cubit);

    final temperatureText = tester.widget<Text>(find.text('21.4'));
    final humidityText = tester.widget<Text>(find.text('48%'));

    expect(humidityText.style?.fontSize,
        lessThan(temperatureText.style!.fontSize!));
    expect(find.byIcon(Icons.water_drop_rounded), findsOneWidget);
  });

  testWidgets('starts carousel on reference sensor without reordering cards',
      (tester) async {
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      controlState: const DeviceSlice<Map<String, dynamic>>.ready(
        data: {
          'climateSensors': [
            {
              'id': 'air',
              'name': 'Air',
              'ref': false,
              'kind': 'air',
              'temp_valid': true,
              'temp_stale': false,
              'temp': 21.4,
              'humidity_valid': false,
            },
            {
              'id': 'floor',
              'name': 'Floor',
              'ref': true,
              'kind': 'floor',
              'temp_valid': true,
              'temp_stale': false,
              'temp': 24.8,
              'humidity_valid': false,
            },
            {
              'id': 'pcb',
              'name': 'PCB',
              'ref': false,
              'kind': 'board',
              'temp_valid': true,
              'temp_stale': false,
              'temp': 28.2,
              'humidity_valid': false,
            },
          ],
        },
      ),
    );
    final cubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(snapshot),
    );
    addTearDown(cubit.close);

    await _pumpPanel(tester, cubit);

    final pageViewCenter = tester.getCenter(find.byType(PageView));
    final airCard = find.byKey(const ValueKey('temperature-sensor-card-air'));
    final floorCard =
        find.byKey(const ValueKey('temperature-sensor-card-floor'));

    expect(floorCard, findsOneWidget);
    final floorCenter = tester.getCenter(floorCard);

    expect((floorCenter.dx - pageViewCenter.dx).abs(), lessThan(2));

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(airCard, findsOneWidget);
    final airCenter = tester.getCenter(airCard);
    expect((airCenter.dx - pageViewCenter.dx).abs(), lessThan(2));
  });

  testWidgets('carousel fills panel while adjacent cards peek at screen edges',
      (tester) async {
    final snapshot = _snapshotWithSensors(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'air',
          'name': 'Air',
          'ref': false,
          'temp_valid': true,
          'temp_stale': false,
          'temp': 21.4,
          'humidity_valid': false,
        },
        <String, dynamic>{
          'id': 'floor',
          'name': 'Floor',
          'ref': true,
          'temp_valid': true,
          'temp_stale': false,
          'temp': 24.8,
          'humidity_valid': false,
        },
      ],
    );
    final cubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(snapshot),
    );
    addTearDown(cubit.close);

    await _pumpPanel(tester, cubit);

    final pageViewFinder = find.byType(PageView);
    final pageView = tester.widget<PageView>(pageViewFinder);
    final pageRect = tester.getRect(pageViewFinder);
    final cardRect = tester.getRect(
      find.byKey(const ValueKey('temperature-sensor-card-floor')),
    );

    expect(pageView.controller?.viewportFraction, 0.85);
    expect(pageView.padEnds, isTrue);
    expect(pageRect.left, 0);
    expect(cardRect.left, greaterThan(pageRect.left));
    expect(cardRect.right, lessThan(pageRect.right));

    final airRect = tester.getRect(
      find.byKey(const ValueKey('temperature-sensor-card-air')),
    );
    expect(airRect.left, lessThan(pageRect.left));
    expect(airRect.right, greaterThan(pageRect.left));
  });

  testWidgets('loads first history preview for reference sensor',
      (tester) async {
    final history = _RecordingTelemetryHistoryApi();
    final snapshot = _snapshotWithSensors(
      const [
        {
          'id': 'air',
          'name': 'Air',
          'ref': false,
          'kind': 'air',
          'temp_valid': true,
          'temp_stale': false,
          'temp': 21.4,
          'humidity_valid': false,
        },
        {
          'id': 'floor',
          'name': 'Floor',
          'ref': true,
          'kind': 'floor',
          'temp_valid': true,
          'temp_stale': false,
          'temp': 24.8,
          'humidity_valid': false,
        },
        {
          'id': 'pcb',
          'name': 'PCB',
          'ref': false,
          'kind': 'board',
          'temp_valid': true,
          'temp_stale': false,
          'temp': 28.2,
          'humidity_valid': false,
        },
      ],
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final cubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit,
      facade: facade,
      showHistoryPreview: true,
    );
    await tester.pump();

    expect(
      history.requests,
      const <String>['climate_sensors.floor.temp'],
    );
  });

  testWidgets('fades in history backdrop chart', (tester) async {
    final history = _RecordingTelemetryHistoryApi();
    final snapshot = _snapshotWithSensors(
      const [
        {
          'id': 'floor',
          'name': 'Floor',
          'ref': true,
          'kind': 'floor',
          'temp_valid': true,
          'temp_stale': false,
          'temp': 24.8,
          'humidity_valid': false,
        },
      ],
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final cubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit,
      facade: facade,
      showHistoryPreview: true,
    );
    await tester.pump();

    final switchers = tester.widgetList<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );

    expect(
      switchers.any(
        (switcher) => switcher.duration == const Duration(milliseconds: 500),
      ),
      isTrue,
    );
  });

  testWidgets('history preview follows swiped temperature card',
      (tester) async {
    final history = _RecordingTelemetryHistoryApi();
    String? openedSensorId;
    final snapshot = _snapshotWithSensors(
      const [
        {
          'id': 'air',
          'name': 'Air',
          'ref': false,
          'kind': 'air',
          'temp_valid': true,
          'temp_stale': false,
          'temp': 21.4,
          'humidity_valid': false,
        },
        {
          'id': 'floor',
          'name': 'Floor',
          'ref': true,
          'kind': 'floor',
          'temp_valid': true,
          'temp_stale': false,
          'temp': 24.8,
          'humidity_valid': false,
        },
        {
          'id': 'pcb',
          'name': 'PCB',
          'ref': false,
          'kind': 'board',
          'temp_valid': true,
          'temp_stale': false,
          'temp': 28.2,
          'humidity_valid': false,
        },
      ],
    );
    final facade = _FakeDeviceFacade(snapshot, history);
    final cubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit,
      facade: facade,
      showHistoryPreview: true,
      onOpenHistory: (sensors, sensorId, sensorName) {
        openedSensorId = sensorId;
      },
    );
    await tester.pump();

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(openedSensorId, isNull);

    expect(
      history.requests,
      containsAllInOrder(
        const <String>[
          'climate_sensors.floor.temp',
          'climate_sensors.pcb.temp',
        ],
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('temperature-history-preview-pcb')),
    );

    expect(openedSensorId, 'pcb');
  });

  testWidgets('upward card drag does not open history but chart action does',
      (tester) async {
    var openCount = 0;
    String? openedSensorId;
    final snapshot = _snapshotWithSensors(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'air',
          'name': 'Air',
          'ref': true,
          'temp_valid': true,
          'temp_stale': false,
          'temp': 21.4,
          'humidity_valid': false,
        },
      ],
    );
    final cubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(snapshot),
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit,
      onOpenHistory: (sensors, sensorId, sensorName) {
        openCount++;
        openedSensorId = sensorId;
      },
    );

    final card = find.byKey(
      const ValueKey('temperature-sensor-card-air'),
    );
    await tester.timedDrag(
      card,
      const Offset(0, -30),
      const Duration(milliseconds: 500),
    );
    await tester.pump();
    expect(openCount, 0);

    await tester.timedDrag(
      card,
      const Offset(0, -70),
      const Duration(milliseconds: 500),
    );
    await tester.pump();

    expect(openCount, 0);
    expect(openedSensorId, isNull);

    await tester.tap(
      find.byKey(const ValueKey('temperature-history-preview-air')),
    );

    expect(openCount, 1);
    expect(openedSensorId, 'air');
  });

  testWidgets('shows heating fire only on the selected sensor card',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final snapshot = _snapshotWithSensors(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'air',
          'name': 'Air',
          'ref': false,
          'temp_valid': true,
          'temp_stale': false,
          'temp': 21.4,
          'humidity_valid': false,
        },
        <String, dynamic>{
          'id': 'floor',
          'name': 'Floor',
          'ref': true,
          'temp_valid': true,
          'temp_stale': false,
          'temp': 24.8,
          'humidity_valid': false,
        },
      ],
      controls: const <String, dynamic>{'heaterEnabled': true},
    );
    final cubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(snapshot),
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit,
      heatingStatusBind: 'heaterEnabled',
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(const ValueKey('thermostat-heating-fire-image')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Heating on'), findsOneWidget);

    final airOffstage = tester.widget<Offstage>(
      find.descendant(
        of: find.byKey(
          const ValueKey('thermostat-heating-indicator-air'),
          skipOffstage: false,
        ),
        matching: find.byType(Offstage, skipOffstage: false),
        skipOffstage: false,
      ),
    );
    final floorOffstage = tester.widget<Offstage>(
      find.descendant(
        of: find.byKey(
          const ValueKey('thermostat-heating-indicator-floor'),
          skipOffstage: false,
        ),
        matching: find.byType(Offstage, skipOffstage: false),
        skipOffstage: false,
      ),
    );
    expect(airOffstage.offstage, isTrue);
    expect(floorOffstage.offstage, isFalse);

    await tester.drag(find.byType(PageView), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('thermostat-heating-fire-image')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Offstage>(
            find.descendant(
              of: find.byKey(
                const ValueKey('thermostat-heating-indicator-air'),
                skipOffstage: false,
              ),
              matching: find.byType(Offstage, skipOffstage: false),
              skipOffstage: false,
            ),
          )
          .offstage,
      isFalse,
    );
    semantics.dispose();
  });

  testWidgets('hides fire for off and unavailable heating states',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final offSnapshot = _snapshotWithSensors(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'air',
          'name': 'Air',
          'ref': true,
          'temp_valid': true,
          'temp_stale': false,
          'temp': 21.4,
          'humidity_valid': false,
        },
      ],
      controls: const <String, dynamic>{'heaterEnabled': false},
    );
    final offCubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(offSnapshot),
    );
    addTearDown(offCubit.close);

    await _pumpPanel(
      tester,
      offCubit,
      heatingStatusBind: 'heaterEnabled',
    );

    expect(
      find.byKey(const ValueKey('thermostat-heating-fire-image')),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Heating off'), findsOneWidget);

    final unknownSnapshot = _snapshotWithSensors(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'air',
          'name': 'Air',
          'ref': true,
          'temp_valid': true,
          'temp_stale': false,
          'temp': 21.4,
          'humidity_valid': false,
        },
      ],
      controls: const <String, dynamic>{'heaterEnabled': 'unknown'},
    );
    final unknownCubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(unknownSnapshot),
    );
    addTearDown(unknownCubit.close);

    await _pumpPanel(
      tester,
      unknownCubit,
      heatingStatusBind: 'heaterEnabled',
    );

    expect(
      find.byKey(const ValueKey('thermostat-heating-fire-image')),
      findsNothing,
    );
    expect(
      find.bySemanticsLabel('Heating status unavailable'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('does not show heating fire on the add sensor page',
      (tester) async {
    final snapshot = _snapshotWithSensors(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'air',
          'name': 'Air',
          'ref': true,
          'temp_valid': true,
          'temp_stale': false,
          'temp': 21.4,
          'humidity_valid': false,
        },
      ],
      controls: const <String, dynamic>{'heaterEnabled': true},
    );
    final cubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(snapshot),
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit,
      heatingStatusBind: 'heaterEnabled',
      onAddSensorTap: () {},
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byKey(const ValueKey('thermostat-heating-fire-image')),
      findsOneWidget,
    );

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Add sensor'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('thermostat-heating-fire-image')),
      findsNothing,
    );
  });

  testWidgets('shows heating fire on the fallback temperature card',
      (tester) async {
    final snapshot = _snapshotWithSensors(
      const <Map<String, dynamic>>[],
      controls: const <String, dynamic>{
        'ambientTemperature': 22.4,
        'heaterEnabled': true,
      },
    );
    final cubit = DeviceSnapshotCubit(
      facade: _FakeDeviceFacade(snapshot),
    );
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit,
      heatingStatusBind: 'heaterEnabled',
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byKey(
        const ValueKey('thermostat-heating-indicator-fallback'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('thermostat-heating-fire-image')),
      findsOneWidget,
    );
  });

  testWidgets('reserves compact vertical space for configured heating status',
      (tester) async {
    final snapshot = _snapshotWithSensors(
      const <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'air',
          'name': 'Air',
          'ref': true,
          'temp_valid': true,
          'temp_stale': false,
          'temp': 21.4,
          'humidity_valid': true,
          'humidity': 48,
        },
      ],
      controls: const <String, dynamic>{'heaterEnabled': true},
    );
    final facade = _FakeDeviceFacade(snapshot);
    final cubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(cubit.close);

    await _pumpPanel(
      tester,
      cubit,
      facade: facade,
      showHistoryPreview: true,
    );
    await tester.pump();
    final baselineTop = tester.getTopLeft(find.text('21.4')).dy;

    await _pumpPanel(
      tester,
      cubit,
      facade: facade,
      showHistoryPreview: true,
      heatingStatusBind: 'heaterEnabled',
    );
    await tester.pump();
    final configuredTop = tester.getTopLeft(find.text('21.4')).dy;

    expect(configuredTop - baselineTop, closeTo(24, 0.01));
  });

  testWidgets('moves to reference sensor when ref metadata arrives after boot',
      (tester) async {
    final facade = _MutableDeviceFacade(
      _snapshotWithSensors(
        const [
          {
            'id': 'air',
            'name': 'Air',
            'kind': 'air',
            'temp_valid': true,
            'temp_stale': false,
            'temp': 21.4,
            'humidity_valid': false,
          },
          {
            'id': 'floor',
            'name': 'Floor',
            'kind': 'floor',
            'temp_valid': true,
            'temp_stale': false,
            'temp': 24.8,
            'humidity_valid': false,
          },
        ],
      ),
    );
    final cubit = DeviceSnapshotCubit(facade: facade)..start();
    addTearDown(cubit.close);
    addTearDown(facade.close);

    await _pumpPanel(tester, cubit);

    facade.emit(
      _snapshotWithSensors(
        const [
          {
            'id': 'air',
            'name': 'Air',
            'ref': false,
            'kind': 'air',
            'temp_valid': true,
            'temp_stale': false,
            'temp': 21.4,
            'humidity_valid': false,
          },
          {
            'id': 'floor',
            'name': 'Floor',
            'ref': true,
            'kind': 'floor',
            'temp_valid': true,
            'temp_stale': false,
            'temp': 24.8,
            'humidity_valid': false,
          },
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    final pageViewCenter = tester.getCenter(find.byType(PageView));
    final floorCenter = tester.getCenter(
      find.byKey(const ValueKey('temperature-sensor-card-floor')),
    );

    expect((floorCenter.dx - pageViewCenter.dx).abs(), lessThan(2));
  });
}

DeviceSnapshot _snapshotWithSensors(
  List<Map<String, dynamic>> sensors, {
  Map<String, dynamic> controls = const <String, dynamic>{},
}) {
  return DeviceSnapshot.initial(device: _device()).copyWith(
    controlState: DeviceSlice<Map<String, dynamic>>.ready(
      data: {
        'climateSensors': sensors,
        ...controls,
      },
    ),
  );
}

Future<void> _pumpPanel(
  WidgetTester tester,
  DeviceSnapshotCubit cubit, {
  DeviceFacade? facade,
  bool showHistoryPreview = false,
  OnOpenTemperatureHistory? onOpenHistory,
  String? heatingStatusBind,
  VoidCallback? onAddSensorTap,
}) {
  Widget app = BlocProvider<DeviceSnapshotCubit>.value(
    value: cubit,
    child: MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: showHistoryPreview ? 360 : 260,
          child: TemperatureMinimalPanel(
            currentBind: 'ambientTemperature',
            sensorsBind: 'climateSensors',
            currentTargetBind: 'scheduleCurrentTarget',
            nextTargetBind: 'scheduleNextTarget',
            heatingStatusBind: heatingStatusBind,
            showHistoryPreview: showHistoryPreview,
            onOpenHistory: onOpenHistory,
            onAddSensorTap: onAddSensorTap,
          ),
        ),
      ),
    ),
  );

  if (facade != null) {
    app = RepositoryProvider<DeviceFacade>.value(
      value: facade,
      child: app,
    );
  }

  return tester.pumpWidget(app);
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

final class _FakeDeviceFacade implements DeviceFacade {
  const _FakeDeviceFacade(
    this._snapshot, [
    this._history = const _EmptyTelemetryHistoryApi(),
  ]);

  final DeviceSnapshot _snapshot;
  final DeviceTelemetryHistoryApi _history;

  @override
  DeviceSnapshot get current => _snapshot;

  @override
  Stream<DeviceSnapshot> watch() => const Stream<DeviceSnapshot>.empty();

  @override
  DeviceTelemetryHistoryApi get telemetryHistory => _history;

  @override
  Future<void> refreshAll({bool forceGet = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecordingTelemetryHistoryApi implements DeviceTelemetryHistoryApi {
  final List<String> requests = <String>[];

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) async {
    requests.add(seriesKey);
    return TelemetryHistorySeries(
      deviceId: 'device-1',
      serial: 'SN-1',
      seriesKey: seriesKey,
      resolution: 'auto',
      from: from,
      to: to,
      points: <TelemetryHistoryPoint>[
        TelemetryHistoryPoint(
          bucketStart: from,
          samplesCount: 1,
          avgValue: 21.5,
        ),
        TelemetryHistoryPoint(
          bucketStart: to,
          samplesCount: 1,
          avgValue: 22.0,
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _EmptyTelemetryHistoryApi implements DeviceTelemetryHistoryApi {
  const _EmptyTelemetryHistoryApi();

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
    TelemetryHistoryApiVersion apiVersion = TelemetryHistoryApiVersion.v1,
  }) async {
    return TelemetryHistorySeries(
      deviceId: 'device-1',
      serial: 'SN-1',
      seriesKey: seriesKey,
      resolution: 'auto',
      from: from,
      to: to,
      points: const <TelemetryHistoryPoint>[],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _MutableDeviceFacade implements DeviceFacade {
  _MutableDeviceFacade(this._current);

  final StreamController<DeviceSnapshot> _controller =
      StreamController<DeviceSnapshot>.broadcast();
  DeviceSnapshot _current;

  void emit(DeviceSnapshot snapshot) {
    _current = snapshot;
    _controller.add(snapshot);
  }

  Future<void> close() => _controller.close();

  @override
  DeviceSnapshot get current => _current;

  @override
  Stream<DeviceSnapshot> watch() => _controller.stream;

  @override
  Future<void> refreshAll({bool forceGet = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
