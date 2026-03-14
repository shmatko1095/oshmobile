import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_sensor.dart';
import 'package:oshmobile/features/telemetry_history/presentation/pages/telemetry_history_page.dart';

class TelemetryHistoryNavigator {
  const TelemetryHistoryNavigator._();

  static void openLoadFactorFromHost(BuildContext hostContext) {
    _openMetrics(
      hostContext,
      metrics: const <TelemetryHistoryMetric>[
        TelemetryHistoryMetric(
          title: 'Load factor',
          seriesKey: 'load_factor',
          kind: TelemetryHistoryMetricKind.numeric,
          unit: '%',
        ),
      ],
    );
  }

  static void openHeatingFromHost(BuildContext hostContext) {
    _openMetrics(
      hostContext,
      metrics: const <TelemetryHistoryMetric>[
        TelemetryHistoryMetric(
          title: 'Heating activity',
          seriesKey: 'heater_enabled',
          kind: TelemetryHistoryMetricKind.boolean,
        ),
      ],
    );
  }

  static void openTemperatureFromHost(
    BuildContext hostContext, {
    required String sensorId,
    String? sensorName,
    List<TelemetryHistorySensor> sensors = const <TelemetryHistorySensor>[],
  }) {
    final normalizedId = sensorId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    final normalizedSensors = sensors
        .where((sensor) => sensor.id.trim().isNotEmpty)
        .toList(growable: false);

    final metrics = normalizedSensors.isEmpty
        ? <TelemetryHistoryMetric>[
            TelemetryHistoryMetric(
              title: 'Temperature',
              subtitle: sensorName == null || sensorName.trim().isEmpty
                  ? normalizedId
                  : sensorName.trim(),
              seriesKey: 'climate_sensors.$normalizedId.temp',
              kind: TelemetryHistoryMetricKind.numeric,
              unit: '°C',
              sensorId: normalizedId,
            ),
          ]
        : normalizedSensors
            .map(
              (sensor) => TelemetryHistoryMetric(
                title: 'Temperature',
                subtitle:
                    sensor.name.trim().isEmpty ? sensor.id : sensor.name.trim(),
                seriesKey: 'climate_sensors.${sensor.id}.temp',
                kind: TelemetryHistoryMetricKind.numeric,
                unit: '°C',
                sensorId: sensor.id,
                isPrimarySensor: sensor.ref,
              ),
            )
            .toList(growable: false);

    final initialIndex = metrics
        .indexWhere((m) => m.seriesKey == 'climate_sensors.$normalizedId.temp');

    _openMetrics(
      hostContext,
      metrics: metrics,
      initialMetricIndex: initialIndex < 0 ? 0 : initialIndex,
    );
  }

  static void _openMetrics(
    BuildContext hostContext, {
    required List<TelemetryHistoryMetric> metrics,
    int initialMetricIndex = 0,
  }) {
    if (metrics.isEmpty) return;
    if (!hostContext.mounted) return;

    late final DeviceFacade facade;
    late final DeviceSnapshotCubit snapshotCubit;
    try {
      facade = hostContext.read<DeviceFacade>();
      snapshotCubit = hostContext.read<DeviceSnapshotCubit>();
    } catch (_) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: 'Device scope is not available in the current context.',
      );
      return;
    }

    Navigator.of(hostContext).push(
      MaterialPageRoute(
        builder: (_) => DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: BlocProvider(
            create: (_) => TelemetryHistoryCubit(
              telemetryHistoryApi: facade.telemetryHistory,
              metrics: metrics,
              initialMetricIndex: initialMetricIndex,
            )..load(),
            child: const TelemetryHistoryPage(),
          ),
        ),
      ),
    );
  }
}
