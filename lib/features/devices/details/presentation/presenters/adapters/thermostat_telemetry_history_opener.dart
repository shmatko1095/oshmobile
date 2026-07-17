import 'package:flutter/material.dart';
import 'package:oshmobile/app/device_session/domain/models/device_temperature_sensor_ref.dart';
import 'package:oshmobile/core/configuration/models/configuration_history.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';
import 'package:oshmobile/features/telemetry_history/presentation/open_telemetry_history.dart';

class ThermostatTelemetryHistoryOpener {
  const ThermostatTelemetryHistoryOpener();

  VoidCallback? prepareDashboard(
    BuildContext context, {
    required String title,
    required ConfigurationHistory history,
    required List<DeviceTemperatureSensorRef> sensors,
    String? initialSensorId,
  }) {
    return TelemetryHistoryNavigator.prepareDashboardFromHost(
      context,
      title: title,
      history: history,
      sensors: sensors,
      initialSensorId: initialSensorId,
    );
  }

  void open(
    BuildContext context, {
    required TelemetryHistoryIntent intent,
  }) {
    TelemetryHistoryNavigator.openPowerMeterFromHost(
      context,
      initialSeriesKey: intent.initialSeriesKey,
      configuredSeriesKeys: intent.configuredSeriesKeys,
    );
  }

  void openHeating(BuildContext context) {
    TelemetryHistoryNavigator.openHeatingFromHost(context);
  }

  void openLoadFactor(BuildContext context) {
    TelemetryHistoryNavigator.openLoadFactorFromHost(context);
  }
}
