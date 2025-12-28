String newReqId() => DateTime.now().millisecondsSinceEpoch.toString();

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
