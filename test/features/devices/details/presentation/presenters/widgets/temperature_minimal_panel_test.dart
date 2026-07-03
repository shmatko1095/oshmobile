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
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
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

    expect(airCard, findsOneWidget);
    expect(floorCard, findsOneWidget);

    final airCenter = tester.getCenter(airCard);
    final floorCenter = tester.getCenter(floorCard);

    expect((floorCenter.dx - pageViewCenter.dx).abs(), lessThan(2));
    expect(airCenter.dx, lessThan(floorCenter.dx));
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

DeviceSnapshot _snapshotWithSensors(List<Map<String, dynamic>> sensors) {
  return DeviceSnapshot.initial(device: _device()).copyWith(
    controlState: DeviceSlice<Map<String, dynamic>>.ready(
      data: {
        'climateSensors': sensors,
      },
    ),
  );
}

Future<void> _pumpPanel(
  WidgetTester tester,
  DeviceSnapshotCubit cubit,
) {
  return tester.pumpWidget(
    BlocProvider<DeviceSnapshotCubit>.value(
      value: cubit,
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: SizedBox(
            height: 260,
            child: TemperatureMinimalPanel(
              currentBind: 'ambientTemperature',
              sensorsBind: 'climateSensors',
              currentTargetBind: 'scheduleCurrentTarget',
              nextTargetBind: 'scheduleNextTarget',
            ),
          ),
        ),
      ),
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

final class _FakeDeviceFacade implements DeviceFacade {
  const _FakeDeviceFacade(this._snapshot);

  final DeviceSnapshot _snapshot;

  @override
  DeviceSnapshot get current => _snapshot;

  @override
  Stream<DeviceSnapshot> watch() => const Stream<DeviceSnapshot>.empty();

  @override
  Future<void> refreshAll({bool forceGet = false}) async {}

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
