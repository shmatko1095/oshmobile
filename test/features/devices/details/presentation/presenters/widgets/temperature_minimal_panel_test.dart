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

    await tester.pumpWidget(
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

    expect(find.text('21.4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('temperature-stale-indicator-air')),
      findsOneWidget,
    );
    expect(find.text('No temperature data'), findsNothing);
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
