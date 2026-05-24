import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric_catalog.dart';

void main() {
  test('energy metric uses sum semantics and kWh scaling', () {
    final energyDefinition = TelemetryHistoryMetricCatalog.powerMeterDefinitions
        .firstWhere(
          (definition) =>
              definition.seriesKey ==
              TelemetryHistoryMetricCatalog.powerMeterEnergyWhDelta,
        );

    expect(energyDefinition.useSumValue, isTrue);
    expect(energyDefinition.unit, 'kWh');
    expect(energyDefinition.valueMultiplier, 0.001);
  });
}
