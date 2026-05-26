import 'package:flutter/material.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';
import 'package:oshmobile/features/telemetry_history/presentation/open_telemetry_history.dart';

class ThermostatTelemetryHistoryOpener {
  const ThermostatTelemetryHistoryOpener();

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
}
