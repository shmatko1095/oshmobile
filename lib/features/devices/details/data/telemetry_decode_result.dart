import 'package:oshmobile/core/network/mqtt/protocol/v1/telemetry_decode_issue.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/telemetry_state.dart';

final class TelemetryDecodeResult {
  final TelemetryState state;
  final List<TelemetryDecodeIssue> issues;

  const TelemetryDecodeResult({
    required this.state,
    required this.issues,
  });
}
