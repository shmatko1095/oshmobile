class SensorEditorEntry {
  final String id;
  final String name;
  final bool ref;
  final String? kind;
  final bool tempValid;
  final bool humidityValid;
  final double? temp;
  final double? humidity;

  const SensorEditorEntry({
    required this.id,
    required this.name,
    required this.ref,
    required this.kind,
    required this.tempValid,
    required this.humidityValid,
    required this.temp,
    required this.humidity,
  });

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return id;
  }
}
