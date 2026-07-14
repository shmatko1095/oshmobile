import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_kind.dart';

class TelemetrySetpointState {
  const TelemetrySetpointState._({
    required this.kind,
    required this.temperature,
  });

  const TelemetrySetpointState.inactive()
      : this._(
          kind: TelemetrySetpointKind.inactive,
          temperature: null,
        );

  const TelemetrySetpointState.temperature(double value)
      : this._(
          kind: TelemetrySetpointKind.temperature,
          temperature: value,
        );

  const TelemetrySetpointState.on()
      : this._(
          kind: TelemetrySetpointKind.on,
          temperature: null,
        );

  const TelemetrySetpointState.off()
      : this._(
          kind: TelemetrySetpointKind.off,
          temperature: null,
        );

  final TelemetrySetpointKind kind;
  final double? temperature;

  @override
  bool operator ==(Object other) =>
      other is TelemetrySetpointState &&
      other.kind == kind &&
      other.temperature == temperature;

  @override
  int get hashCode => Object.hash(kind, temperature);
}
