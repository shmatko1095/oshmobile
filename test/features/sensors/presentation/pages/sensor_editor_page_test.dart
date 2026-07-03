import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/sensors/presentation/models/sensor_editor_entry.dart';
import 'package:oshmobile/features/sensors/presentation/pages/sensor_editor_page.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  testWidgets('shows stale temperature as display-only data', (tester) async {
    final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
      telemetry: const DeviceSlice<Map<String, dynamic>>.ready(
        data: {
          'climate_sensors': [
            {
              'id': 'floor',
              'temp_valid': false,
              'temp_stale': true,
              'temp': 21.4,
              'humidity_valid': false,
            },
          ],
        },
      ),
    );
    final facade = _FakeDeviceFacade(snapshot);
    final cubit = DeviceSnapshotCubit(facade: facade);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: cubit,
          child: const SensorEditorPage(
            sensor: SensorEditorEntry(
              id: 'floor',
              name: 'Floor',
              ref: false,
              kind: 'floor',
              tempValid: false,
              tempStale: false,
              humidityValid: false,
              temp: null,
              humidity: null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('21.4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sensor-editor-temp-stale-floor')),
      findsOneWidget,
    );
  });
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
  _FakeDeviceFacade(this._snapshot)
      : _sensors = _FakeDeviceSensorsApi(
          const SensorsState(
            pairing: SensorPairing(
              enabled: false,
              transport: 'zigbee',
              timeoutSec: 0,
              startedTs: 0,
            ),
            items: [
              SensorMeta(
                id: 'floor',
                name: 'Floor',
                ref: false,
                transport: 'zigbee',
                removable: true,
                kind: 'floor',
              ),
            ],
          ),
        );

  final DeviceSnapshot _snapshot;
  final _FakeDeviceSensorsApi _sensors;

  @override
  DeviceSnapshot get current => _snapshot;

  @override
  Stream<DeviceSnapshot> watch() => const Stream<DeviceSnapshot>.empty();

  @override
  Future<void> refreshAll({bool forceGet = false}) async {}

  @override
  DeviceSensorsApi get sensors => _sensors;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeDeviceSensorsApi implements DeviceSensorsApi {
  const _FakeDeviceSensorsApi(this._state);

  final SensorsState _state;

  @override
  SensorsState? get current => _state;

  @override
  Stream<SensorsState> watch() => const Stream<SensorsState>.empty();

  @override
  Future<void> setReference({required String id}) async {}

  @override
  Future<void> remove({required String id, bool? leave}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
