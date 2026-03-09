import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
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

  TelemetryState? decodeState(Map<String, dynamic> data) {
    if (!_validator.validateStatePayload(data)) return null;
    return TelemetryState.fromJson(data);
  }
}
