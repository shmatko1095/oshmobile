import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/models/device_temperature_sensor_ref.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';
import 'package:oshmobile/features/telemetry_history/presentation/pages/telemetry_history_page.dart';
import 'package:oshmobile/generated/l10n.dart';

class TelemetryHistoryNavigator {
  const TelemetryHistoryNavigator._();

  static void openLoadFactorFromHost(BuildContext hostContext) {
    final s = S.of(hostContext);
    _openMetrics(
      hostContext,
      metrics: <TelemetryHistoryMetric>[
        TelemetryHistoryMetricCatalog.loadFactorMetric(s),
      ],
    );
  }

  static void openHeatingFromHost(BuildContext hostContext) {
    final s = S.of(hostContext);
    _openMetrics(
      hostContext,
      metrics: <TelemetryHistoryMetric>[
        TelemetryHistoryMetricCatalog.heatingActivityMetric(s),
      ],
    );
  }

  static void openPowerMeterFromHost(
    BuildContext hostContext, {
    required String initialSeriesKey,
    required Iterable<String> configuredSeriesKeys,
  }) {
    final s = S.of(hostContext);
    final metrics = TelemetryHistoryMetricCatalog.powerMeterMetrics(
      s,
      configuredSeriesKeys: configuredSeriesKeys,
    );
    if (metrics.isEmpty) {
      return;
    }

    _openMetrics(
      hostContext,
      metrics: metrics,
      initialMetricIndex:
          TelemetryHistoryMetricCatalog.initialIndexForSeriesKey(
        metrics,
        initialSeriesKey,
      ),
    );
  }

  static void openTemperatureFromHost(
    BuildContext hostContext, {
    required String sensorId,
    String? sensorName,
    List<DeviceTemperatureSensorRef> sensors =
        const <DeviceTemperatureSensorRef>[],
  }) {
    final normalizedId = sensorId.trim();
    if (normalizedId.isEmpty) {
      return;
    }
    final s = S.of(hostContext);

    final normalizedSensors = sensors
        .where((sensor) => sensor.id.trim().isNotEmpty)
        .toList(growable: false);

    final metrics = normalizedSensors.isEmpty
        ? <TelemetryHistoryMetric>[
            TelemetryHistoryMetric(
              title: s.TelemetryHistoryMetricTemperature,
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
                title: s.TelemetryHistoryMetricTemperature,
                subtitle:
                    sensor.name.trim().isEmpty ? sensor.id : sensor.name.trim(),
                seriesKey: 'climate_sensors.${sensor.id}.temp',
                kind: TelemetryHistoryMetricKind.numeric,
                unit: '°C',
                sensorId: sensor.id,
                isPrimarySensor: sensor.isReference,
              ),
            )
            .toList(growable: false);

    final initialIndex = metrics
        .indexWhere((m) => m.seriesKey == 'climate_sensors.$normalizedId.temp');

    _openMetrics(
      hostContext,
      metrics: metrics,
      comparisonMetrics: <TelemetryHistoryMetric>[
        TelemetryHistoryMetricCatalog.heatingActivityMetric(s),
      ],
      initialMetricIndex: initialIndex < 0 ? 0 : initialIndex,
    );
  }

  static void _openMetrics(
    BuildContext hostContext, {
    required List<TelemetryHistoryMetric> metrics,
    List<TelemetryHistoryMetric> comparisonMetrics =
        const <TelemetryHistoryMetric>[],
    int initialMetricIndex = 0,
  }) {
    if (metrics.isEmpty) return;
    if (!hostContext.mounted) return;
    final s = S.of(hostContext);
    final effectiveIndex = initialMetricIndex.clamp(0, metrics.length - 1);
    unawaited(
      OshAnalytics.logEvent(
        OshAnalyticsEvents.telemetryHistoryOpened,
        parameters: {
          'metric_key': _analyticsMetricKey(metrics[effectiveIndex]),
          'comparison_count': comparisonMetrics.length,
        },
      ),
    );

    late final DeviceFacade facade;
    late final DeviceSnapshotCubit snapshotCubit;
    try {
      facade = hostContext.read<DeviceFacade>();
      snapshotCubit = hostContext.read<DeviceSnapshotCubit>();
    } catch (_) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: s.DeviceScopeUnavailableInContext,
      );
      return;
    }

    Navigator.of(hostContext).push(
      MaterialPageRoute(
        settings: const RouteSettings(
          name: OshAnalyticsScreens.telemetryHistory,
        ),
        builder: (_) => DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: BlocProvider(
            create: (_) => TelemetryHistoryCubit(
              seriesReader: facade.telemetryHistory,
              setpointReader: facade.telemetryHistory,
              metrics: metrics,
              comparisonMetrics: comparisonMetrics,
              initialMetricIndex: effectiveIndex,
            )..load(),
            child: const TelemetryHistoryPage(),
          ),
        ),
      ),
    );
  }

  static String _analyticsMetricKey(TelemetryHistoryMetric metric) {
    if (metric.sensorId != null && metric.sensorId!.trim().isNotEmpty) {
      return 'temperature';
    }

    return switch (metric.seriesKey) {
      TelemetryHistoryMetricCatalog.loadFactor => 'load_factor',
      TelemetryHistoryMetricCatalog.heaterEnabled => 'heater_enabled',
      TelemetryHistoryMetricCatalog.targetTemp => 'target_temp',
      TelemetryHistoryMetricCatalog.powerMeterVoltageV => 'power_meter_voltage',
      TelemetryHistoryMetricCatalog.powerMeterCurrentA => 'power_meter_current',
      TelemetryHistoryMetricCatalog.powerMeterActivePowerW =>
        'power_meter_active_power',
      TelemetryHistoryMetricCatalog.powerMeterApparentPowerVa =>
        'power_meter_apparent_power',
      TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta =>
        'power_meter_energy_used',
      _ => 'metric',
    };
  }
}
