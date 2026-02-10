bool hasOnlyKeys(Map<String, dynamic> map, Set<String> allowed) {
  for (final key in map.keys) {
    if (!allowed.contains(key)) return false;
  }
  return true;
}

bool hasRequiredKeys(Map<String, dynamic> map, Set<String> required) {
  for (final key in required) {
    if (!map.containsKey(key)) return false;
  }
  return true;
}

String? asString(dynamic v) {
  if (v is String) return v;
  return null;
}

bool? asBool(dynamic v) {
  if (v is bool) return v;
  return null;
}

int? asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return null;
}

num? asNum(dynamic v) {
  if (v is num) return v;
  return null;
}

bool inRangeInt(int v, int min, int max) => v >= min && v <= max;

bool validStringLength(String v, {int? min, int? max}) {
  if (min != null && v.length < min) return false;
  if (max != null && v.length > max) return false;
  return true;
}
