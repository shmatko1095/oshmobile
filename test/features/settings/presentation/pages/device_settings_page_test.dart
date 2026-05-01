import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/features/settings/presentation/pages/device_settings_page.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  setUp(() {
    OshAnalytics.debugSetBackend(_FakeAnalyticsBackend());
  });

  tearDown(() {
    OshAnalytics.debugResetBackend();
  });

  testWidgets(
    'renders root and child groups, keeps dirty state, and shows discard only on root',
    (tester) async {
      final harness = _SettingsTestHarness();
      await harness.pump(tester);

      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();

      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Heating control'), findsOneWidget);
      expect(find.text('Dims the display while idle.'), findsOneWidget);

      await tester.tap(find.text('Heating control'));
      await tester.pumpAndSettle();

      expect(find.text('Control model'), findsOneWidget);
      expect(
        find.text(
          'TPI changes relay ON time within a 10 min cycle to keep the reference temperature near the target.\nUsually better for smooth setpoint holding; relay switching is limited to at least 2 min per state.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(DropdownButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('R2C').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'R2C estimates how the room and thermal mass heat and cool, then adjusts relay ON time within a 15 min cycle.\nUsually better for more inertial heating systems; relay switching is limited to at least 2 min per state.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Unsaved changes'), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Unsaved changes'), findsOneWidget);
    },
  );

  testWidgets('save from nested child closes the entire settings flow', (
    tester,
  ) async {
    final harness = _SettingsTestHarness();
    await harness.pump(tester);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Heating control'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Floor protection'));
    await tester.pumpAndSettle();

    expect(find.text('Max floor temperature'), findsOneWidget);
    expect(
      find.text(
        'When the floor reaches this temperature, heating will be turned off.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(harness.settingsApi.saveCalls, 1);
    expect(find.text('Launcher'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('boolean field description follows the current toggle value', (
    tester,
  ) async {
    final harness = _SettingsTestHarness();
    await harness.pump(tester);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Heating control'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Floor protection'));
    await tester.pumpAndSettle();

    expect(find.text('Floor sensor fail-safe'), findsOneWidget);
    expect(
      find.text(
        'Heating is turned off when floor reference sensor data is unavailable.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Heating continues when floor reference sensor data is unavailable.',
      ),
      findsOneWidget,
    );
  });
}

class _SettingsTestHarness {
  _SettingsTestHarness()
      : schema = _buildSchema(),
        facade = _FakeDeviceFacade(
          schema: _buildSchema(),
          initialSnapshot: SettingsSnapshot.fromJson({
            'display': {
              'dimOnIdle': true,
            },
            'control': {
              'model': 'tpi',
              'maxFloorTemp': 32.0,
              'maxFloorTempLimitEnabled': true,
              'maxFloorTempFailSafe': false,
            },
          }),
        );

  final SettingsUiSchema schema;
  final _FakeDeviceFacade facade;

  _FakeDeviceSettingsApi get settingsApi =>
      facade.settings as _FakeDeviceSettingsApi;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Launcher'),
                    ElevatedButton(
                      onPressed: () {
                        final cubit = DeviceSnapshotCubit(facade: facade)
                          ..start();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            settings: const RouteSettings(
                              name: OshAnalyticsScreens.deviceSettings,
                            ),
                            builder: (_) => DeviceRouteScope.provide(
                              facade: facade,
                              snapshotCubit: cubit,
                              child: DeviceSettingsPage(schema: schema),
                            ),
                          ),
                        );
                      },
                      child: const Text('Open settings'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

SettingsUiSchema _buildSchema() {
  return const SettingsUiSchema(
    fieldsByPath: {
      'display.dimOnIdle': SettingsUiField(
        id: 'displayDimOnIdle',
        path: 'display.dimOnIdle',
        section: 'display',
        key: 'dimOnIdle',
        type: SettingsUiFieldType.boolean,
        widget: SettingsUiWidget.toggle,
        writable: true,
        groupId: 'display',
        titleKey: 'Dim on idle',
        descriptionKey: 'Dims the display while idle.',
      ),
      'control.model': SettingsUiField(
        id: 'controlModel',
        path: 'control.model',
        section: 'control',
        key: 'model',
        type: SettingsUiFieldType.enumeration,
        widget: SettingsUiWidget.select,
        writable: true,
        groupId: 'control',
        titleKey: 'Control model',
        descriptionKey: 'Fallback control model description',
        enumValues: ['tpi', 'r2c', 'hysteresis'],
        enumOptions: {
          'tpi': SettingsUiEnumOption(
            value: 'tpi',
            titleKey: 'TPI fallback',
            descriptionKey: 'Fallback TPI description',
          ),
          'r2c': SettingsUiEnumOption(
            value: 'r2c',
            titleKey: 'R2C fallback',
            descriptionKey: 'Fallback R2C description',
          ),
          'hysteresis': SettingsUiEnumOption(
            value: 'hysteresis',
            titleKey: 'Hysteresis fallback',
            descriptionKey: 'Fallback hysteresis description',
          ),
        },
      ),
      'control.maxFloorTemp': SettingsUiField(
        id: 'maxFloorTemperature',
        path: 'control.maxFloorTemp',
        section: 'control',
        key: 'maxFloorTemp',
        type: SettingsUiFieldType.number,
        widget: SettingsUiWidget.slider,
        writable: true,
        groupId: 'controlLimits',
        titleKey: 'Max floor temperature',
        descriptionKey:
            'When the floor reaches this temperature, heating will be turned off.',
        min: 10,
        max: 50,
        step: 0.5,
        unit: '°C',
      ),
      'control.maxFloorTempLimitEnabled': SettingsUiField(
        id: 'maxFloorTempLimitEnabled',
        path: 'control.maxFloorTempLimitEnabled',
        section: 'control',
        key: 'maxFloorTempLimitEnabled',
        type: SettingsUiFieldType.boolean,
        widget: SettingsUiWidget.toggle,
        writable: true,
        groupId: 'controlLimits',
        titleKey: 'Floor temperature limit',
        descriptionKey:
            'Use the configured maximum floor temperature as a heating limit.',
      ),
      'control.maxFloorTempFailSafe': SettingsUiField(
        id: 'maxFloorTempFailSafe',
        path: 'control.maxFloorTempFailSafe',
        section: 'control',
        key: 'maxFloorTempFailSafe',
        type: SettingsUiFieldType.boolean,
        widget: SettingsUiWidget.toggle,
        writable: true,
        groupId: 'controlLimits',
        titleKey: 'Floor sensor fail-safe',
        descriptionKey: 'Fallback generic fail-safe description',
        booleanOptions: {
          true: SettingsUiBooleanOption(
            value: true,
            descriptionKey: 'Fallback true fail-safe description',
          ),
          false: SettingsUiBooleanOption(
            value: false,
            descriptionKey: 'Fallback false fail-safe description',
          ),
        },
      ),
    },
    groupsById: {
      'display': SettingsUiGroup(
        id: 'display',
        titleKey: 'Display',
        presentation: SettingsUiGroupPresentation.inline,
        order: ['display.dimOnIdle'],
      ),
      'control': SettingsUiGroup(
        id: 'control',
        titleKey: 'Heating control',
        presentation: SettingsUiGroupPresentation.screen,
        order: ['control.model'],
        childGroupIds: ['controlLimits'],
      ),
      'controlLimits': SettingsUiGroup(
        id: 'controlLimits',
        titleKey: 'Floor protection',
        parentGroupId: 'control',
        presentation: SettingsUiGroupPresentation.screen,
        order: [
          'control.maxFloorTemp',
          'control.maxFloorTempLimitEnabled',
          'control.maxFloorTempFailSafe',
        ],
      ),
    },
    rootGroupIds: ['display', 'control'],
  );
}

class _FakeAnalyticsBackend implements AnalyticsBackend {
  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object?>? parameters,
  }) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}

final class _FakeDeviceFacade implements DeviceFacade {
  _FakeDeviceFacade({
    required SettingsUiSchema schema,
    required SettingsSnapshot initialSnapshot,
  })  : _schema = schema,
        _state = DeviceSnapshot.initial(device: _device()).copyWith(
          settings: DeviceSlice<SettingsSnapshot>.ready(
            data: initialSnapshot,
            dirty: false,
          ),
          settingsUiSchema: schema,
        ),
        _settingsApi = _FakeDeviceSettingsApi(initialSnapshot);

  final SettingsUiSchema _schema;
  final StreamController<DeviceSnapshot> _controller =
      StreamController<DeviceSnapshot>.broadcast();
  late final _FakeDeviceSettingsApi _settingsApi;
  DeviceSnapshot _state;

  @override
  DeviceSnapshot get current => _state;

  @override
  SettingsUiSchema? get settingsUiSchema => _schema;

  @override
  Stream<DeviceSnapshot> watch() => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> refreshAll({bool forceGet = false}) async {}

  @override
  DeviceScheduleApi get schedule => _FakeDeviceScheduleApi();

  @override
  DeviceSettingsApi get settings {
    _settingsApi.attach(this);
    return _settingsApi;
  }

  @override
  DeviceSensorsApi get sensors => _FakeDeviceSensorsApi();

  @override
  DeviceTelemetryApi get telemetry => _FakeDeviceTelemetryApi();

  @override
  DeviceTelemetryHistoryApi get telemetryHistory =>
      _FakeDeviceTelemetryHistoryApi();

  @override
  DeviceAboutApi get about => _FakeDeviceAboutApi();

  void emitSettings(SettingsSnapshot snapshot, {required bool dirty}) {
    _state = _state.copyWith(
      settings: DeviceSlice<SettingsSnapshot>.ready(
        data: snapshot,
        dirty: dirty,
      ),
      updatedAt: DateTime.now(),
    );
    _controller.add(_state);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

final class _FakeDeviceSettingsApi implements DeviceSettingsApi {
  _FakeDeviceSettingsApi(SettingsSnapshot initialSnapshot)
      : _base = initialSnapshot;

  late _FakeDeviceFacade _facade;
  SettingsSnapshot _base;
  int saveCalls = 0;
  int discardCalls = 0;

  void attach(_FakeDeviceFacade facade) {
    _facade = facade;
  }

  @override
  SettingsSnapshot? get current => _facade.current.settings.data;

  @override
  Stream<SettingsSnapshot> watch() => const Stream<SettingsSnapshot>.empty();

  @override
  Future<SettingsSnapshot> get({bool force = false}) async {
    return current ?? _base;
  }

  @override
  void patch(String path, Object? value) {
    final next = (current ?? _base).copyWithValue(path, value);
    _facade.emitSettings(next, dirty: true);
  }

  @override
  void patchAll(Map<String, Object?> patch) {
    var next = current ?? _base;
    patch.forEach((path, value) {
      next = next.copyWithValue(path, value);
    });
    _facade.emitSettings(next, dirty: true);
  }

  @override
  DeviceSettingsDisplayApi get display => _FakeDeviceSettingsDisplayApi(this);

  @override
  DeviceSettingsUpdateApi get update => _FakeDeviceSettingsUpdateApi(this);

  @override
  DeviceSettingsTimeApi get time => _FakeDeviceSettingsTimeApi(this);

  @override
  Future<void> save() async {
    saveCalls += 1;
    final snapshot = current;
    if (snapshot == null) return;
    _base = snapshot;
    _facade.emitSettings(snapshot, dirty: false);
  }

  @override
  void discardLocalChanges() {
    discardCalls += 1;
    _facade.emitSettings(_base, dirty: false);
  }
}

final class _FakeDeviceSettingsDisplayApi implements DeviceSettingsDisplayApi {
  const _FakeDeviceSettingsDisplayApi(this._api);

  final _FakeDeviceSettingsApi _api;

  @override
  void setActiveBrightness(int value) =>
      _api.patch('display.activeBrightness', value);

  @override
  void setIdleBrightness(int value) =>
      _api.patch('display.idleBrightness', value);

  @override
  void setIdleTime(int value) => _api.patch('display.idleTime', value);

  @override
  void setDimOnIdle(bool value) => _api.patch('display.dimOnIdle', value);

  @override
  void setLanguage(String value) => _api.patch('display.language', value);
}

final class _FakeDeviceSettingsUpdateApi implements DeviceSettingsUpdateApi {
  const _FakeDeviceSettingsUpdateApi(this._api);

  final _FakeDeviceSettingsApi _api;

  @override
  void setAutoUpdateEnabled(bool value) =>
      _api.patch('update.autoUpdateEnabled', value);

  @override
  void setUpdateAtMidnight(bool value) =>
      _api.patch('update.updateAtMidnight', value);

  @override
  void setCheckIntervalMin(int value) =>
      _api.patch('update.checkIntervalMin', value);
}

final class _FakeDeviceSettingsTimeApi implements DeviceSettingsTimeApi {
  const _FakeDeviceSettingsTimeApi(this._api);

  final _FakeDeviceSettingsApi _api;

  @override
  void setAuto(bool value) => _api.patch('time.auto', value);

  @override
  void setTimeZone(int value) => _api.patch('time.timeZone', value);
}

final class _FakeDeviceScheduleApi implements DeviceScheduleApi {
  @override
  CalendarSnapshot? get current => null;

  @override
  Stream<CalendarSnapshot> watch() => const Stream<CalendarSnapshot>.empty();

  @override
  Future<CalendarSnapshot> get({bool force = false}) async =>
      CalendarSnapshot.empty(CalendarMode.off);

  @override
  Future<void> commandSetMode(
    CalendarMode mode, {
    String source = 'unknown',
  }) async {}

  @override
  void patchRange(ScheduleRange range) {}

  @override
  void patchList(CalendarMode mode, List<SchedulePoint> points) {}

  @override
  void patchPoint(int index, SchedulePoint point) {}

  @override
  void removePoint(int index) {}

  @override
  void addPoint([SchedulePoint? point, int stepMinutes = 15]) {}

  @override
  Future<void> save() async {}

  @override
  void discardLocalChanges() {}
}

final class _FakeDeviceSensorsApi implements DeviceSensorsApi {
  @override
  SensorsState? get current => null;

  @override
  Stream<SensorsState> watch() => const Stream<SensorsState>.empty();

  @override
  Future<SensorsState> get({bool force = false}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> patch(SensorsPatch patch) async {}

  @override
  Future<void> save(SensorsSetPayload payload) async {}

  @override
  Future<void> rename({
    required String id,
    required String name,
  }) async {}

  @override
  Future<void> setReference({required String id}) async {}

  @override
  Future<void> setTempCalibration({
    required String id,
    required double value,
  }) async {}

  @override
  Future<void> remove({
    required String id,
    bool? leave,
  }) async {}
}

final class _FakeDeviceTelemetryApi implements DeviceTelemetryApi {
  @override
  Map<String, dynamic> get current => const <String, dynamic>{};

  @override
  Stream<Map<String, dynamic>> watch() =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Future<Map<String, dynamic>> get({bool force = false}) async =>
      const <String, dynamic>{};
}

final class _FakeDeviceTelemetryHistoryApi
    implements DeviceTelemetryHistoryApi {
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
      resolution: preferredResolution,
      from: from,
      to: to,
      points: const [],
    );
  }
}

final class _FakeDeviceAboutApi implements DeviceAboutApi {
  @override
  Map<String, dynamic>? get current => const <String, dynamic>{};

  @override
  Stream<Map<String, dynamic>> watch() =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Future<Map<String, dynamic>?> get({bool force = false}) async =>
      const <String, dynamic>{};

  @override
  Future<void> stop() async {}
}

Device _device() {
  return Device(
    id: 'device-1',
    sn: 'SN-1',
    modelId: 'model-1',
    modelName: 'Test thermostat',
    userData: const DeviceUserData(
      alias: 'Thermostat',
      description: '',
    ),
    connectionInfo: ConnectionInfo(online: true),
  );
}
