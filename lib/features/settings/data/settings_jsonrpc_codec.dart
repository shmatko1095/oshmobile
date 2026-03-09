import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/features/settings/data/settings_payload_validator.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';

/// Codec for settings@1 JSON-RPC payloads.
///
/// Body shape:
/// {
///   "display": {...},
///   "update": {...},
///   ...
/// }
class SettingsJsonRpcCodec {
  final SettingsPayloadValidator _validator;

  const SettingsJsonRpcCodec._(this._validator);

  factory SettingsJsonRpcCodec.fromRuntimeContract(
    RuntimeDomainContract contract,
  ) {
    return SettingsJsonRpcCodec._(
      SettingsPayloadValidator(
        stateSchema: contract.stateSchema,
        setSchema: contract.setSchema,
        patchSchema: contract.patchSchema,
      ),
    );
  }

  SettingsSnapshot? decodeBody(Map<String, dynamic> data) {
    if (!_validator.validateStatePayload(data)) return null;
    return SettingsSnapshot.fromJson(data);
  }

  Map<String, dynamic> encodeBody(SettingsSnapshot snapshot) {
    final data = snapshot.toJson();
    if (!_validator.validateSetPayload(data)) {
      throw FormatException('Invalid settings payload');
    }
    return data;
  }

  Map<String, dynamic> encodePatch(Map<String, dynamic> patch) {
    if (!_validator.validatePatchPayload(patch)) {
      throw FormatException('Invalid settings patch payload');
    }
    return patch;
  }
}
