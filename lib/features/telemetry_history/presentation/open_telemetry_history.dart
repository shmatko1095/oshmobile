import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/pages/telemetry_history_page.dart';

class TelemetryHistoryNavigator {
  const TelemetryHistoryNavigator._();

  static void openLoadFactorFromHost(BuildContext hostContext) {
    _openMetric(
      hostContext,
      metric: const TelemetryHistoryMetric(
        title: 'Load factor',
        seriesKey: 'load_factor',
        kind: TelemetryHistoryMetricKind.numeric,
        unit: '%',
      ),
    );
  }

  static void openHeatingFromHost(BuildContext hostContext) {
    _openMetric(
      hostContext,
      metric: const TelemetryHistoryMetric(
        title: 'Heating activity',
        seriesKey: 'heater_enabled',
        kind: TelemetryHistoryMetricKind.boolean,
      ),
    );
  }

  static void openTemperatureFromHost(
    BuildContext hostContext, {
    required String sensorId,
    String? sensorName,
  }) {
    final normalizedId = sensorId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    _openMetric(
      hostContext,
      metric: TelemetryHistoryMetric(
        title: 'Temperature',
        subtitle: sensorName == null || sensorName.trim().isEmpty
            ? normalizedId
            : sensorName.trim(),
        seriesKey: 'climate_sensors.$normalizedId.temp',
        kind: TelemetryHistoryMetricKind.numeric,
        unit: '°C',
      ),
    );
  }

  static void _openMetric(
    BuildContext hostContext, {
    required TelemetryHistoryMetric metric,
  }) {
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
          child: TelemetryHistoryPage(metric: metric),
        ),
      ),
    );
  }
}
