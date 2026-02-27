import 'dart:convert';
import 'dart:math';

final Random _reqIdRandom = Random();
int _reqIdCounter = 0;

String newReqId() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  _reqIdCounter = (_reqIdCounter + 1) & 0xFFFF;
  final rnd = _reqIdRandom.nextInt(1 << 20);
  return '$ts-${_reqIdCounter.toRadixString(16)}-${rnd.toRadixString(16)}';
}

/// Returns true if [payload] contains request id equal to [expected].
/// Supported payload shapes:
/// - String: payload == expected
/// - Map: payload['reqId'] == expected
/// - Map: payload['data']['reqId'] == expected
bool matchesReqId(dynamic payload, String expected) {
  if (payload == null) return false;
  if (payload is String) return payload == expected;

  if (payload is Map) {
    final direct = payload['reqId']?.toString();
    if (direct == expected) return true;

    final data = payload['data'];
    if (data is Map && data['reqId']?.toString() == expected) return true;
  }

  return false;
}

/// Decodes MQTT JSON payload into a Map<String, dynamic>.
/// Supports:
/// - Map<String, dynamic>
/// - Map (casted)
/// - JSON String (decoded)
///
/// Returns empty map for invalid / unsupported payloads.
Map<String, dynamic> decodeMqttMap(dynamic raw) {
  try {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();

    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    }
  } catch (_) {
    // Swallow decode errors to keep streams alive.
  }

  return const <String, dynamic>{};
}

/// Extracts applied reqId from a decoded MQTT map.
///
/// Supported shapes:
/// - { "reqId": "123" }
/// - { "data": { "reqId": "123" } }
String? extractReqIdFromMap(Map<String, dynamic> map) {
  final v = map['reqId'];
  if (v != null) return v.toString();

  final data = map['data'];
  if (data is Map && data['reqId'] != null) {
    return data['reqId'].toString();
  }

  return null;
}
