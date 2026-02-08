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
  static const String schema = 'settings@1';
  static const String domain = 'settings';

  static String methodOf(String op) => '$domain.$op';

  static String get methodState => methodOf('state');
  static String get methodGet => methodOf('get');
  static String get methodSet => methodOf('set');
  static String get methodPatch => methodOf('patch');

  static SettingsSnapshot decodeBody(Map<String, dynamic> data) {
    return SettingsSnapshot.fromJson(data);
  }

  static Map<String, dynamic> encodeBody(SettingsSnapshot snapshot) {
    return snapshot.toJson();
  }
}
