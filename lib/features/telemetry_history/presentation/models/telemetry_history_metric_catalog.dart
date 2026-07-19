import 'package:oshmobile/core/configuration/power_meter_series_keys.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_definition.dart';
import 'package:oshmobile/generated/l10n.dart';

class TelemetryHistoryMetricCatalog {
  const TelemetryHistoryMetricCatalog._();

  static const String loadFactor = 'load_factor';
  static const String heaterEnabled = 'heater_enabled';
  static const String targetTemp = 'target_temp';
  static const String setpointOn = 'setpoint_on';
  static const String setpointOff = 'setpoint_off';
  static const String powerMeterVoltageV = PowerMeterSeriesKeys.voltageV;
  static const String powerMeterCurrentA = PowerMeterSeriesKeys.currentA;
  static const String powerMeterActivePowerW =
      PowerMeterSeriesKeys.activePowerW;
  static const String powerMeterApparentPowerVa =
      PowerMeterSeriesKeys.apparentPowerVa;
  static const String powerMeterEnergyWhDelta =
      PowerMeterSeriesKeys.energyWhDelta;
  static const String energyUsage = 'usage.energy';
  static const String heatingUsage = 'usage.heating';

  static const TelemetryHistoryMetricDefinition loadFactorDefinition =
      TelemetryHistoryMetricDefinition(
    title: _loadFactorTitle,
    seriesKey: loadFactor,
    kind: TelemetryHistoryMetricKind.numeric,
    unit: '%',
  );

  static const TelemetryHistoryMetricDefinition heatingActivityDefinition =
      TelemetryHistoryMetricDefinition(
    title: _heatingActivityTitle,
    seriesKey: heaterEnabled,
    kind: TelemetryHistoryMetricKind.boolean,
  );

  static const TelemetryHistoryMetricDefinition targetTempDefinition =
      TelemetryHistoryMetricDefinition(
    title: _targetTitle,
    seriesKey: targetTemp,
    kind: TelemetryHistoryMetricKind.numeric,
    unit: '°C',
  );

  static const TelemetryHistoryMetricDefinition setpointOnDefinition =
      TelemetryHistoryMetricDefinition(
    title: _targetTitle,
    seriesKey: setpointOn,
    kind: TelemetryHistoryMetricKind.boolean,
  );

  static const TelemetryHistoryMetricDefinition setpointOffDefinition =
      TelemetryHistoryMetricDefinition(
    title: _targetTitle,
    seriesKey: setpointOff,
    kind: TelemetryHistoryMetricKind.boolean,
  );

  static const List<TelemetryHistoryMetricDefinition> powerMeterDefinitions =
      <TelemetryHistoryMetricDefinition>[
    TelemetryHistoryMetricDefinition(
      title: _energyUsedTitle,
      seriesKey: powerMeterEnergyWhDelta,
      kind: TelemetryHistoryMetricKind.numeric,
      unit: 'kWh',
      fractionDigits: 3,
      useSumValue: true,
      valueMultiplier: 0.001,
      displayMode: TelemetryHistoryMetricDisplayMode.energyDelta,
    ),
    TelemetryHistoryMetricDefinition(
      title: _voltageTitle,
      seriesKey: powerMeterVoltageV,
      kind: TelemetryHistoryMetricKind.numeric,
      unit: 'V',
    ),
    TelemetryHistoryMetricDefinition(
      title: _currentTitle,
      seriesKey: powerMeterCurrentA,
      kind: TelemetryHistoryMetricKind.numeric,
      unit: 'A',
      fractionDigits: 2,
    ),
    TelemetryHistoryMetricDefinition(
      title: _activePowerTitle,
      seriesKey: powerMeterActivePowerW,
      kind: TelemetryHistoryMetricKind.numeric,
      unit: 'W',
    ),
    TelemetryHistoryMetricDefinition(
      title: _apparentPowerTitle,
      seriesKey: powerMeterApparentPowerVa,
      kind: TelemetryHistoryMetricKind.numeric,
      unit: 'VA',
    ),
  ];

  static TelemetryHistoryMetric loadFactorMetric(S s) {
    return loadFactorDefinition.build(s);
  }

  static TelemetryHistoryMetric energyUsageMetric(S s) {
    return TelemetryHistoryMetric(
      title: s.TelemetryHistoryMetricEnergyUsed,
      seriesKey: energyUsage,
      kind: TelemetryHistoryMetricKind.numeric,
      unit: 'kWh',
      fractionDigits: 3,
      useSumValue: true,
      displayMode: TelemetryHistoryMetricDisplayMode.energyUsage,
    );
  }

  static TelemetryHistoryMetric heatingUsageMetric(S s) {
    return TelemetryHistoryMetric(
      title: s.TelemetryHistoryMetricLoadFactor,
      seriesKey: heatingUsage,
      kind: TelemetryHistoryMetricKind.numeric,
      unit: '%',
      fractionDigits: 0,
      displayMode: TelemetryHistoryMetricDisplayMode.heatingUsage,
    );
  }

  static TelemetryHistoryMetric heatingActivityMetric(S s) {
    return heatingActivityDefinition.build(s);
  }

  static TelemetryHistoryMetric targetTempMetric(S s) {
    return targetTempDefinition.build(s);
  }

  static TelemetryHistoryMetric setpointOnMetric(S s) {
    return setpointOnDefinition.build(s);
  }

  static TelemetryHistoryMetric setpointOffMetric(S s) {
    return setpointOffDefinition.build(s);
  }

  static List<TelemetryHistoryMetric> powerMeterMetrics(
    S s, {
    Iterable<String>? configuredSeriesKeys,
  }) {
    final configured = configuredSeriesKeys
        ?.map((key) => key.trim())
        .where((key) => key.isNotEmpty)
        .toSet();
    return powerMeterDefinitions
        .where(
          (definition) =>
              configured == null || configured.contains(definition.seriesKey),
        )
        .map((definition) => definition.build(s))
        .toList(growable: false);
  }

  static int initialIndexForSeriesKey(
    List<TelemetryHistoryMetric> metrics,
    String? seriesKey,
  ) {
    final normalizedKey = seriesKey?.trim();
    if (normalizedKey == null || normalizedKey.isEmpty) {
      return 0;
    }
    final index =
        metrics.indexWhere((metric) => metric.seriesKey == normalizedKey);
    return index < 0 ? 0 : index;
  }
}

String _loadFactorTitle(S s) => s.TelemetryHistoryMetricLoadFactor;
String _heatingActivityTitle(S s) => s.TelemetryHistoryMetricHeatingActivity;
String _targetTitle(S s) => s.TelemetryHistoryMetricTarget;
String _voltageTitle(S s) => s.TelemetryHistoryMetricVoltage;
String _currentTitle(S s) => s.TelemetryHistoryMetricCurrent;
String _activePowerTitle(S s) => s.TelemetryHistoryMetricActivePower;
String _apparentPowerTitle(S s) => s.TelemetryHistoryMetricApparentPower;
String _energyUsedTitle(S s) => s.TelemetryHistoryMetricEnergyUsed;
