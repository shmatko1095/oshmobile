import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/generated/l10n.dart';

typedef TelemetryHistoryMetricTitleBuilder = String Function(S s);

class TelemetryHistoryMetricDefinition {
  const TelemetryHistoryMetricDefinition({
    required this.seriesKey,
    required this.kind,
    required this.title,
    this.unit = '',
    this.fractionDigits = 1,
    this.useSumValue = false,
    this.valueMultiplier = 1.0,
    this.displayMode = TelemetryHistoryMetricDisplayMode.line,
  });

  final String seriesKey;
  final TelemetryHistoryMetricKind kind;
  final TelemetryHistoryMetricTitleBuilder title;
  final String unit;
  final int fractionDigits;
  final bool useSumValue;
  final double valueMultiplier;
  final TelemetryHistoryMetricDisplayMode displayMode;

  TelemetryHistoryMetric build(S s) {
    return TelemetryHistoryMetric(
      title: title(s),
      seriesKey: seriesKey,
      kind: kind,
      unit: unit,
      fractionDigits: fractionDigits,
      useSumValue: useSumValue,
      valueMultiplier: valueMultiplier,
      displayMode: displayMode,
    );
  }
}
