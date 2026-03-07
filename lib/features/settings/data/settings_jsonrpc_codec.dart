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
  static SettingsSnapshot? decodeBody(Map<String, dynamic> data) {
    if (!validateSettingsSetPayload(data)) return null;
    return SettingsSnapshot.fromJson(data);
  }

  static Map<String, dynamic> encodeBody(SettingsSnapshot snapshot) {
    final data = snapshot.toJson();
    if (!validateSettingsSetPayload(data)) {
      throw FormatException('Invalid settings payload');
    }
    return data;
  }

  static Map<String, dynamic> encodePatch(Map<String, dynamic> patch) {
    if (!validateSettingsPatchPayload(patch)) {
      throw FormatException('Invalid settings patch payload');
    }
    return patch;
  }
}
