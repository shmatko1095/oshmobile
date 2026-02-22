class DeviceStatePayload {
  /// Raw, schema-validated device state payload (`device_state@1`).
  final Map<String, dynamic> raw;

  const DeviceStatePayload._(this.raw);

  factory DeviceStatePayload.fromJson(Map<String, dynamic> json) {
    final parsed = tryParse(json);
    if (parsed == null) {
      throw const FormatException('Invalid device_state@1 payload');
    }
    return parsed;
  }

  static DeviceStatePayload? tryParse(Map<String, dynamic> json) {
    const allowed = {'Uptime', 'Relay cycles', 'Chip temp', 'PCB temp'};
    const required = {'Uptime', 'Relay cycles', 'Chip temp', 'PCB temp'};

    if (!_hasOnlyKeys(json, allowed) || !_hasRequiredKeys(json, required))
      return null;

    final uptime = json['Uptime'];
    final relayCycles = _asFiniteNum(json['Relay cycles']);
    final chipTemp = _asFiniteNum(json['Chip temp']);
    final pcbTemp = _asFiniteNum(json['PCB temp']);

    if (uptime is! String ||
        relayCycles == null ||
        chipTemp == null ||
        pcbTemp == null) {
      return null;
    }

    return DeviceStatePayload._(Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(raw);
}

bool _hasOnlyKeys(Map<String, dynamic> map, Set<String> allowed) {
  for (final key in map.keys) {
    if (!allowed.contains(key)) return false;
  }
  return true;
}

bool _hasRequiredKeys(Map<String, dynamic> map, Set<String> required) {
  for (final key in required) {
    if (!map.containsKey(key)) return false;
  }
  return true;
}

num? _asFiniteNum(dynamic v) {
  if (v is! num) return null;
  if (v.isNaN || v.isInfinite) return null;
  return v;
}
