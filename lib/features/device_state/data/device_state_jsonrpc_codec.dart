import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/device_state_models.dart';
import 'package:oshmobile/features/device_state/data/device_state_payload_validator.dart';

class DeviceStateJsonRpcCodec {
  final DeviceStatePayloadValidator _validator;

  const DeviceStateJsonRpcCodec._(this._validator);

  factory DeviceStateJsonRpcCodec.fromRuntimeContract(
    RuntimeDomainContract contract,
  ) {
    return DeviceStateJsonRpcCodec._(
      DeviceStatePayloadValidator(
        stateSchema: contract.stateSchema,
      ),
    );
  }

  DeviceStatePayload? decodeState(Map<String, dynamic> data) {
    if (!_validator.validateStatePayload(data)) return null;
    return DeviceStatePayload.tryParse(data);
  }
}
