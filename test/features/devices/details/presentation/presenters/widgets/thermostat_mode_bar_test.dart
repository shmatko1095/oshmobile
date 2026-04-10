import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/open_mode_editor.dart';
import 'package:oshmobile/features/schedule/presentation/pages/manual_temperature_page.dart';
import 'package:oshmobile/features/schedule/presentation/pages/range_page.dart';
import 'package:oshmobile/features/schedule/presentation/pages/schedule_editor_page.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/ui/settings_ui_schema.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/telemetry_history_series_reader.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingAnalyticsBackend backend;

  setUp(() async {
    await locator.reset();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    locator.registerSingleton<SharedPreferences>(prefs);

    backend = _RecordingAnalyticsBackend();
    OshAnalytics.debugSetBackend(backend);
  });

  tearDown(() async {
    OshAnalytics.debugResetBackend();
    await locator.reset();
  });

  testWidgets('tap inactive editable mode switches without opening editor',
      (tester) async {
    final harness = await _pumpHarness(
      tester,
      currentMode: CalendarMode.off,
      child: const ThermostatModeBar(modeBind: 'mode'),
    );

    await tester.tap(find.text('Range'));
    await tester.pumpAndSettle();

    expect(
      harness.scheduleApi.commandSetModeCalls,
      <CalendarMode>[CalendarMode.range],
    );
    expect(find.byType(ScheduleRangePage), findsNothing);
    expect(find.byType(ManualTemperaturePage), findsNothing);
    expect(find.byType(ScheduleEditorPage), findsNothing);
  });

  testWidgets('tap active editable mode opens editor and dismisses hint',
      (tester) async {
    final harness = await _pumpHarness(
      tester,
      currentMode: CalendarMode.on,
      child: const ThermostatModeBar(modeBind: 'mode'),
    );

    expect(
      find.text(
        'Tap active mode to edit. Hold any mode to configure without switching.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('On'));
    await tester.pumpAndSettle();

    expect(find.byType(ManualTemperaturePage), findsOneWidget);
    expect(harness.scheduleApi.commandSetModeCalls, isEmpty);

    final event = backend.lastEvent(OshAnalyticsEvents.scheduleEditorOpened);
    final params = event?.parameters;
    expect(params?['mode'], CalendarMode.on.id);
    expect(params?['source'], 'mode_bar_active_tap');

    Navigator.of(tester.element(find.byType(ManualTemperaturePage))).pop();
    await tester.pumpAndSettle();

    expect(
      locator<SharedPreferences>()
          .getBool(thermostatModeBarCalendarHintSeenPrefsKey),
      isTrue,
    );
    expect(
      find.text(
        'Tap active mode to edit. Hold any mode to configure without switching.',
      ),
      findsNothing,
    );
  });

  testWidgets('long press inactive weekly opens editor without switching',
      (tester) async {
    final harness = await _pumpHarness(
      tester,
      currentMode: CalendarMode.off,
      child: const ThermostatModeBar(modeBind: 'mode'),
    );

    await tester.longPress(find.text('Weekly').first);
    await tester.pumpAndSettle();

    expect(harness.scheduleApi.commandSetModeCalls, isEmpty);
    expect(find.byType(ScheduleEditorPage), findsOneWidget);

    final page =
        tester.widget<ScheduleEditorPage>(find.byType(ScheduleEditorPage));
    expect(page.mode, CalendarMode.weekly);

    final event = backend.lastEvent(OshAnalyticsEvents.scheduleEditorOpened);
    final params = event?.parameters;
    expect(params?['mode'], CalendarMode.weekly.id);
    expect(params?['source'], 'mode_bar_long_press');
  });

  testWidgets('tap active off does nothing', (tester) async {
    final harness = await _pumpHarness(
      tester,
      currentMode: CalendarMode.off,
      child: const ThermostatModeBar(modeBind: 'mode'),
    );

    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();

    expect(harness.scheduleApi.commandSetModeCalls, isEmpty);
    expect(find.byType(ScheduleRangePage), findsNothing);
    expect(find.byType(ManualTemperaturePage), findsNothing);
    expect(find.byType(ScheduleEditorPage), findsNothing);
  });

  testWidgets('hero panel backup entry opens current mode editor with source',
      (tester) async {
    await _pumpHarness(
      tester,
      currentMode: CalendarMode.range,
      child: Builder(
        builder: (context) {
          return TextButton(
            onPressed: () =>
                ThermostatModeNavigator.openForCurrentMode(context),
            child: const Text('Open'),
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleRangePage), findsOneWidget);

    final event = backend.lastEvent(OshAnalyticsEvents.scheduleEditorOpened);
    final params = event?.parameters;
    expect(params?['mode'], CalendarMode.range.id);
    expect(params?['source'], 'hero_panel');
  });

  testWidgets('persisted hint stays hidden', (tester) async {
    await locator<SharedPreferences>().setBool(
      thermostatModeBarCalendarHintSeenPrefsKey,
      true,
    );

    await _pumpHarness(
      tester,
      currentMode: CalendarMode.on,
      child: const ThermostatModeBar(modeBind: 'mode'),
    );

    expect(
      find.text(
        'Tap active mode to edit. Hold any mode to configure without switching.',
      ),
      findsNothing,
    );
  });
}

Future<_Harness> _pumpHarness(
  WidgetTester tester, {
  required CalendarMode currentMode,
  required Widget child,
  CalendarSnapshot? scheduleSnapshot,
}) async {
  final schedule = scheduleSnapshot ?? _calendarSnapshot(currentMode);
  final deviceSnapshot = DeviceSnapshot.initial(device: _device()).copyWith(
    controlState: DeviceSlice<Map<String, dynamic>>.ready(
      data: <String, dynamic>{'mode': currentMode.id},
    ),
    schedule: DeviceSlice<CalendarSnapshot>.ready(data: schedule),
  );
  final scheduleApi = _FakeDeviceScheduleApi(currentSnapshot: schedule);
  final facade = _FakeDeviceFacade(
    snapshot: deviceSnapshot,
    scheduleApi: scheduleApi,
  );
  final cubit = DeviceSnapshotCubit(facade: facade);

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
        body: RepositoryProvider<DeviceFacade>.value(
          value: facade,
          child: BlocProvider<DeviceSnapshotCubit>.value(
            value: cubit,
            child: Center(child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _Harness(
    facade: facade,
    scheduleApi: scheduleApi,
    cubit: cubit,
  );
}

CalendarSnapshot _calendarSnapshot(CalendarMode mode) {
  return CalendarSnapshot(
    mode: mode,
    lists: <CalendarMode, List<SchedulePoint>>{
      CalendarMode.on: <SchedulePoint>[
        const SchedulePoint(
          time: TimeOfDay(hour: 0, minute: 0),
          daysMask: WeekdayMask.all,
          temp: 21,
        ),
      ],
      CalendarMode.daily: <SchedulePoint>[
        const SchedulePoint(
          time: TimeOfDay(hour: 6, minute: 0),
          daysMask: WeekdayMask.all,
          temp: 22,
        ),
      ],
      CalendarMode.weekly: <SchedulePoint>[
        const SchedulePoint(
          time: TimeOfDay(hour: 7, minute: 30),
          daysMask: WeekdayMask.mon,
          temp: 23,
        ),
      ],
    },
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

final class _Harness {
  const _Harness({
    required this.facade,
    required this.scheduleApi,
    required this.cubit,
  });

  final _FakeDeviceFacade facade;
  final _FakeDeviceScheduleApi scheduleApi;
  final DeviceSnapshotCubit cubit;
}

final class _LoggedEvent {
  const _LoggedEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object?>? parameters;
}

final class _RecordingAnalyticsBackend implements AnalyticsBackend {
  final List<_LoggedEvent> events = <_LoggedEvent>[];

  _LoggedEvent? lastEvent(String name) {
    for (final event in events.reversed) {
      if (event.name == name) return event;
    }
    return null;
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    events.add(_LoggedEvent(name, parameters));
  }

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
    required DeviceSnapshot snapshot,
    required _FakeDeviceScheduleApi scheduleApi,
  })  : _snapshot = snapshot,
        _scheduleApi = scheduleApi;

  final DeviceSnapshot _snapshot;
  final _FakeDeviceScheduleApi _scheduleApi;

  @override
  DeviceSnapshot get current => _snapshot;

  @override
  SettingsUiSchema? get settingsUiSchema => null;

  @override
  Stream<DeviceSnapshot> watch() => const Stream<DeviceSnapshot>.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> refreshAll({bool forceGet = false}) async {}

  @override
  DeviceScheduleApi get schedule => _scheduleApi;

  @override
  DeviceSettingsApi get settings => _FakeDeviceSettingsApi();

  @override
  DeviceSensorsApi get sensors => _FakeDeviceSensorsApi();

  @override
  DeviceTelemetryApi get telemetry => _FakeDeviceTelemetryApi();

  @override
  DeviceTelemetryHistoryApi get telemetryHistory =>
      _FakeDeviceTelemetryHistoryApi();

  @override
  DeviceAboutApi get about => _FakeDeviceAboutApi();

  @override
  Future<void> dispose() async {}
}

final class _FakeDeviceScheduleApi implements DeviceScheduleApi {
  _FakeDeviceScheduleApi({
    required CalendarSnapshot currentSnapshot,
  }) : _currentSnapshot = currentSnapshot;

  CalendarSnapshot _currentSnapshot;
  final List<CalendarMode> commandSetModeCalls = <CalendarMode>[];

  @override
  CalendarSnapshot? get current => _currentSnapshot;

  @override
  Stream<CalendarSnapshot> watch() => const Stream<CalendarSnapshot>.empty();

  @override
  Future<CalendarSnapshot> get({bool force = false}) async => _currentSnapshot;

  @override
  Future<void> commandSetMode(
    CalendarMode mode, {
    String source = 'unknown',
  }) async {
    commandSetModeCalls.add(mode);
  }

  @override
  void patchRange(ScheduleRange range) {}

  @override
  void patchList(CalendarMode mode, List<SchedulePoint> points) {
    _currentSnapshot = _currentSnapshot.copyWith(
      lists: <CalendarMode, List<SchedulePoint>>{
        ..._currentSnapshot.lists,
        mode: points,
      },
    );
  }

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

final class _FakeDeviceSettingsApi implements DeviceSettingsApi {
  @override
  SettingsSnapshot? get current => null;

  @override
  Stream<SettingsSnapshot> watch() => const Stream<SettingsSnapshot>.empty();

  @override
  Future<SettingsSnapshot> get({bool force = false}) {
    throw UnimplementedError();
  }

  @override
  void patch(String path, Object? value) {}

  @override
  void patchAll(Map<String, Object?> patch) {}

  @override
  DeviceSettingsDisplayApi get display => _FakeDeviceSettingsDisplayApi();

  @override
  DeviceSettingsUpdateApi get update => _FakeDeviceSettingsUpdateApi();

  @override
  DeviceSettingsTimeApi get time => _FakeDeviceSettingsTimeApi();

  @override
  Future<void> save() async {}

  @override
  void discardLocalChanges() {}
}

final class _FakeDeviceSettingsDisplayApi implements DeviceSettingsDisplayApi {
  @override
  void setActiveBrightness(int value) {}

  @override
  void setIdleBrightness(int value) {}

  @override
  void setIdleTime(int value) {}

  @override
  void setDimOnIdle(bool value) {}

  @override
  void setLanguage(String value) {}
}

final class _FakeDeviceSettingsUpdateApi implements DeviceSettingsUpdateApi {
  @override
  void setAutoUpdateEnabled(bool value) {}

  @override
  void setUpdateAtMidnight(bool value) {}

  @override
  void setCheckIntervalMin(int value) {}
}

final class _FakeDeviceSettingsTimeApi implements DeviceSettingsTimeApi {
  @override
  void setAuto(bool value) {}

  @override
  void setTimeZone(int value) {}
}

final class _FakeDeviceSensorsApi implements DeviceSensorsApi {
  @override
  SensorsState? get current => null;

  @override
  Stream<SensorsState> watch() => const Stream<SensorsState>.empty();

  @override
  Future<SensorsState> get({bool force = false}) {
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
  Future<void> setReference({
    required String id,
  }) async {}

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
  Map<String, dynamic> get current => <String, dynamic>{};

  @override
  Stream<Map<String, dynamic>> watch() =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Future<Map<String, dynamic>> get({bool force = false}) async =>
      <String, dynamic>{};
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
  Map<String, dynamic>? get current => null;

  @override
  Stream<Map<String, dynamic>> watch() =>
      const Stream<Map<String, dynamic>>.empty();

  @override
  Future<Map<String, dynamic>?> get({bool force = false}) async => null;

  @override
  Future<void> stop() async {}
}
