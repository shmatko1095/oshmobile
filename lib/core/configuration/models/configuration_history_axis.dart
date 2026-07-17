class ConfigurationHistoryAxis {
  const ConfigurationHistoryAxis({
    required this.mode,
    this.min,
    this.max,
  });

  factory ConfigurationHistoryAxis.fromJson(Map<String, dynamic> json) {
    return ConfigurationHistoryAxis(
      mode: json['mode']?.toString() ?? '',
      min: json['min'] is num ? json['min'] as num : null,
      max: json['max'] is num ? json['max'] as num : null,
    );
  }

  final String mode;
  final num? min;
  final num? max;
}
