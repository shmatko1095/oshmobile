class DeviceStatePayload {
  /// Raw, unvalidated device state payload.
  final Map<String, dynamic> raw;

  const DeviceStatePayload._(this.raw);

  factory DeviceStatePayload.fromJson(Map<String, dynamic> json) {
    return DeviceStatePayload._(Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(raw);
}
