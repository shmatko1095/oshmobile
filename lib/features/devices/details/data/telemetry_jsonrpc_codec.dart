import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/telemetry_decode_issue.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/telemetry_state.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_decode_result.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_payload_validator.dart';

class TelemetryJsonRpcCodec {
  final TelemetryPayloadValidator _validator;

  const TelemetryJsonRpcCodec._(this._validator);

  factory TelemetryJsonRpcCodec.fromRuntimeContract(
    RuntimeDomainContract contract,
  ) {
    return TelemetryJsonRpcCodec._(
      TelemetryPayloadValidator(
        stateSchema: contract.stateSchema,
      ),
    );
  }

  TelemetryDecodeResult decodeState(Map<String, dynamic> data) {
    final issues = <TelemetryDecodeIssue>[];
    void addIssue(String path, String reason) {
      issues.add(TelemetryDecodeIssue(path: path, reason: reason));
    }

    if (!_validator.validateStatePayload(data)) {
      addIssue(r'$', 'runtime_schema_mismatch');
    }

    final sanitized = _validator.sanitizeStatePayload(
      data,
      onIssue: addIssue,
    );
    final state = TelemetryState.fromJson(
      sanitized,
      onIssue: issues.add,
    );

    return TelemetryDecodeResult(
      state: state,
      issues: List<TelemetryDecodeIssue>.unmodifiable(issues),
    );
  }
}
