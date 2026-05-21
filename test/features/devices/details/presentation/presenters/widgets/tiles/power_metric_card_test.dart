import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/power_metric_card.dart';

void main() {
  testWidgets('renders electrical metrics with configured units',
      (tester) async {
    await _pumpWithControlState(
      tester,
      controlState: const <String, dynamic>{
        'voltage': 229.7,
        'voltageValid': true,
        'current': 4.256,
        'currentValid': true,
        'apparentPower': 512.5,
        'apparentPowerValid': true,
      },
      child: const Column(
        children: [
          SizedBox(
            width: 170,
            height: 145,
            child: PowerMetricCard(
              valueBind: 'voltage',
              validBind: 'voltageValid',
              title: 'Voltage',
              unit: 'V',
              icon: Icons.electrical_services_rounded,
              accentColor: Colors.amber,
            ),
          ),
          SizedBox(
            width: 170,
            height: 145,
            child: PowerMetricCard(
              valueBind: 'current',
              validBind: 'currentValid',
              title: 'Current',
              unit: 'A',
              icon: Icons.timeline_rounded,
              accentColor: Colors.cyan,
              decimals: 2,
            ),
          ),
          SizedBox(
            width: 170,
            height: 145,
            child: PowerMetricCard(
              valueBind: 'apparentPower',
              validBind: 'apparentPowerValid',
              title: 'Apparent power',
              unit: 'VA',
              icon: Icons.speed_rounded,
              accentColor: Colors.blue,
            ),
          ),
        ],
      ),
    );

    expect(find.text('229.7 V'), findsOneWidget);
    expect(find.text('4.26 A'), findsOneWidget);
    expect(find.text('512.5 VA'), findsOneWidget);
  });

  testWidgets('shows placeholder for invalid or unreadable metric values',
      (tester) async {
    await _pumpWithControlState(
      tester,
      controlState: const <String, dynamic>{
        'validFalseValue': 230,
        'validFalse': false,
        'nonNumericValue': 'not-a-number',
      },
      child: const Column(
        children: [
          SizedBox(
            width: 170,
            height: 145,
            child: PowerMetricCard(
              valueBind: 'validFalseValue',
              validBind: 'validFalse',
              title: 'Voltage',
              unit: 'V',
              icon: Icons.electrical_services_rounded,
              accentColor: Colors.amber,
            ),
          ),
          SizedBox(
            width: 170,
            height: 145,
            child: PowerMetricCard(
              valueBind: 'missingValue',
              title: 'Current',
              unit: 'A',
              icon: Icons.timeline_rounded,
              accentColor: Colors.cyan,
            ),
          ),
          SizedBox(
            width: 170,
            height: 145,
            child: PowerMetricCard(
              valueBind: 'nonNumericValue',
              title: 'Apparent power',
              unit: 'VA',
              icon: Icons.speed_rounded,
              accentColor: Colors.blue,
            ),
          ),
        ],
      ),
    );

    expect(find.text('—'), findsNWidgets(3));
  });

  testWidgets('does not overflow in compact tile constraints', (tester) async {
    await _pumpWithControlState(
      tester,
      controlState: const <String, dynamic>{'apparentPower': 123456.7},
      child: const SizedBox(
        width: 120,
        height: 110,
        child: PowerMetricCard(
          valueBind: 'apparentPower',
          title: 'Apparent power',
          unit: 'VA',
          icon: Icons.speed_rounded,
          accentColor: Colors.blue,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('fires optional tap callback', (tester) async {
    var taps = 0;
    await _pumpWithControlState(
      tester,
      controlState: const <String, dynamic>{'voltage': 230},
      child: SizedBox(
        width: 170,
        height: 145,
        child: PowerMetricCard(
          valueBind: 'voltage',
          title: 'Voltage',
          unit: 'V',
          icon: Icons.electrical_services_rounded,
          accentColor: Colors.amber,
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.byType(PowerMetricCard));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('PowerCard uses optional validity bind', (tester) async {
    await _pumpWithControlState(
      tester,
      controlState: const <String, dynamic>{
        'activePower': 1234,
        'activePowerValid': false,
      },
      child: const SizedBox(
        width: 170,
        height: 145,
        child: PowerCard(
          bind: 'activePower',
          validBind: 'activePowerValid',
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
  });
}

Future<void> _pumpWithControlState(
  WidgetTester tester, {
  required Map<String, dynamic> controlState,
  required Widget child,
}) async {
  final snapshot = DeviceSnapshot.initial(device: _device()).copyWith(
    controlState: DeviceSlice<Map<String, dynamic>>.ready(data: controlState),
  );
  final cubit = DeviceSnapshotCubit(
    facade: _FakeDeviceFacade(snapshot),
  );
  addTearDown(cubit.close);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: BlocProvider<DeviceSnapshotCubit>.value(
            value: cubit,
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
