import 'dart:async';

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
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';
import 'package:oshmobile/features/telemetry_history/presentation/open_telemetry_history.dart';
import 'package:oshmobile/features/telemetry_history/presentation/pages/telemetry_history_page.dart';
import 'package:oshmobile/generated/l10n.dart';

void main() {
  group('TelemetryHistoryNavigator.openPowerMeterFromHost', () {
    testWidgets('opens configured metrics with tapped metric selected',
        (tester) async {
      final history = _QueuedTelemetryHistoryApi();
      final facade = _FakeDeviceFacade(
        DeviceSnapshot.initial(device: _device()),
        history,
      );
      final snapshotCubit = DeviceSnapshotCubit(facade: facade);
      addTearDown(snapshotCubit.close);

      await _pumpHost(
        tester,
        facade: facade,
        snapshotCubit: snapshotCubit,
        onPressed: (context) {
          TelemetryHistoryNavigator.openPowerMeterFromHost(
            context,
            initialSeriesKey: TelemetryHistoryMetricCatalog.powerMeterCurrentA,
            configuredSeriesKeys: const <String>[
              TelemetryHistoryMetricCatalog.powerMeterVoltageV,
              TelemetryHistoryMetricCatalog.powerMeterCurrentA,
            ],
          );
        },
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TelemetryHistoryPage), findsOneWidget);
      expect(find.text('Current'), findsWidgets);
      expect(find.text('Voltage'), findsWidgets);
      expect(find.text('Active power'), findsNothing);
      expect(history.requests, hasLength(1));
      expect(
        history.requests.single.seriesKey,
        TelemetryHistoryMetricCatalog.powerMeterCurrentA,
      );
    });

    testWidgets('does not push when no configured metric is available',
        (tester) async {
      final history = _QueuedTelemetryHistoryApi();
      final facade = _FakeDeviceFacade(
        DeviceSnapshot.initial(device: _device()),
        history,
      );
      final snapshotCubit = DeviceSnapshotCubit(facade: facade);
      addTearDown(snapshotCubit.close);

      await _pumpHost(
        tester,
        facade: facade,
        snapshotCubit: snapshotCubit,
        onPressed: (context) {
          TelemetryHistoryNavigator.openPowerMeterFromHost(
            context,
            initialSeriesKey: TelemetryHistoryMetricCatalog.powerMeterCurrentA,
            configuredSeriesKeys: const <String>[],
          );
        },
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TelemetryHistoryPage), findsNothing);
      expect(history.requests, isEmpty);
    });
  });

  group('TelemetryHistoryNavigator.openTemperatureFromHost', () {
    testWidgets('loads temperature, heating and atomic setpoint history',
        (tester) async {
      final history = _QueuedTelemetryHistoryApi();
      final facade = _FakeDeviceFacade(
        DeviceSnapshot.initial(device: _device()),
        history,
      );
      final snapshotCubit = DeviceSnapshotCubit(facade: facade);
      addTearDown(snapshotCubit.close);

      await _pumpHost(
        tester,
        facade: facade,
        snapshotCubit: snapshotCubit,
        onPressed: (context) {
          TelemetryHistoryNavigator.openTemperatureFromHost(
            context,
            sensorId: 'floor',
            sensorName: 'Floor',
          );
        },
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TelemetryHistoryPage), findsOneWidget);
      expect(
        history.requests.map((request) => request.seriesKey).toSet(),
        <String>{
          'climate_sensors.floor.temp',
          TelemetryHistoryMetricCatalog.heaterEnabled,
        },
      );
      expect(history.setpointRequests, hasLength(1));
    });
  });
}

Future<void> _pumpHost(
  WidgetTester tester, {
  required DeviceFacade facade,
  required DeviceSnapshotCubit snapshotCubit,
  required void Function(BuildContext context) onPressed,
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
      home: DeviceRouteScope.provide(
        facade: facade,
        snapshotCubit: snapshotCubit,
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => onPressed(context),
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pump();
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

final class _QueuedTelemetryHistoryApi implements DeviceTelemetryHistoryApi {
  final List<_Request> requests = <_Request>[];
  final List<Completer<TelemetrySetpointHistory>> setpointRequests =
      <Completer<TelemetrySetpointHistory>>[];

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
  Future<TelemetrySetpointHistory> getSetpointHistory({
    required DateTime from,
    required DateTime to,
    String preferredResolution = 'auto',
  }) {
    final completer = Completer<TelemetrySetpointHistory>();
    setpointRequests.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Request {
  const _Request({
    required this.seriesKey,
    required this.completer,
  });

  final String seriesKey;
  final Completer<TelemetryHistorySeries> completer;
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
