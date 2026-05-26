enum ThermostatTileType {
  heatingToggle,
  loadFactor24h,
  energyUsed,
  powerNow,
  voltageNow,
  currentNow,
  apparentPowerNow,
  inletTemp,
  outletTemp,
  deltaT,
}

enum TelemetryHistoryIntentGroup {
  energy,
  electrical,
}

class TelemetryHistoryIntent {
  const TelemetryHistoryIntent({
    required this.group,
    required this.initialSeriesKey,
    required this.configuredSeriesKeys,
  });

  final TelemetryHistoryIntentGroup group;
  final String initialSeriesKey;
  final List<String> configuredSeriesKeys;
}

class ThermostatHeroSpec {
  const ThermostatHeroSpec({
    required this.currentBind,
    required this.currentTargetBind,
    required this.nextTargetBind,
    required this.sensorsBind,
  });

  final String currentBind;
  final String currentTargetBind;
  final String nextTargetBind;
  final String sensorsBind;
}

class ThermostatModeBarSpec {
  const ThermostatModeBarSpec({
    required this.modeBind,
    required this.visibleModeIds,
  });

  final String modeBind;
  final List<String>? visibleModeIds;
}

class ThermostatTemperatureHistoryStripSpec {
  const ThermostatTemperatureHistoryStripSpec({
    required this.sensorsBind,
  });

  final String sensorsBind;
}

sealed class ThermostatTileSpec {
  const ThermostatTileSpec({
    required this.type,
    this.telemetryHistoryIntent,
  });

  final ThermostatTileType type;
  final TelemetryHistoryIntent? telemetryHistoryIntent;
}

class ThermostatSingleBindTileSpec extends ThermostatTileSpec {
  const ThermostatSingleBindTileSpec({
    required super.type,
    required this.bind,
    super.telemetryHistoryIntent,
  });

  final String bind;
}

class ThermostatValueTileSpec extends ThermostatTileSpec {
  const ThermostatValueTileSpec({
    required super.type,
    required this.valueBind,
    this.validBind,
    super.telemetryHistoryIntent,
  });

  final String valueBind;
  final String? validBind;
}

class ThermostatDeltaTileSpec extends ThermostatTileSpec {
  const ThermostatDeltaTileSpec({
    required this.inletBind,
    required this.outletBind,
  }) : super(type: ThermostatTileType.deltaT);

  final String inletBind;
  final String outletBind;
}

class ThermostatDashboardSchema {
  const ThermostatDashboardSchema({
    required this.hero,
    required this.modeBar,
    required this.temperatureHistoryStrip,
    required this.tiles,
    required this.visibleWidgetIds,
  });

  final ThermostatHeroSpec? hero;
  final ThermostatModeBarSpec? modeBar;
  final ThermostatTemperatureHistoryStripSpec? temperatureHistoryStrip;
  final List<ThermostatTileSpec> tiles;
  final List<String> visibleWidgetIds;
}
