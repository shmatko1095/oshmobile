import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/sensors/data/sensors_payload_validator.dart';

class SensorsJsonRpcCodec {
  final SensorsPayloadValidator _validator;

  const SensorsJsonRpcCodec._(this._validator);

  factory SensorsJsonRpcCodec.fromRuntimeContract(
    RuntimeDomainContract contract,
  ) {
    return SensorsJsonRpcCodec._(
      SensorsPayloadValidator(
        stateSchema: contract.stateSchema,
        setSchema: contract.setSchema,
        patchSchema: contract.patchSchema,
      ),
    );
  }

  SensorsState? decodeState(Map<String, dynamic> data) {
    if (!_validator.validateStatePayload(data)) return null;
    return SensorsState.fromJson(data);
  }

  Map<String, dynamic> encodeSet(SensorsSetPayload payload) {
    final data = payload.toJson();
    if (!_validator.validateSetPayload(data)) {
      throw FormatException('Invalid sensors.set payload');
    }
    return data;
  }

  Map<String, dynamic> encodePatch(SensorsPatch patch) {
    final data = patch.toJson();
    if (!_validator.validatePatchPayload(data)) {
      throw FormatException('Invalid sensors.patch payload');
    }
    return data;
  }
}
