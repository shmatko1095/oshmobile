import 'package:oshmobile/core/configuration/models/configuration_history_axis.dart';

class ConfigurationHistorySeries {
  const ConfigurationHistorySeries({
    required this.id,
    required this.title,
    required this.path,
    required this.valueType,
    required this.unit,
    required this.arrayIdField,
    required this.validField,
    required this.axis,
  });

  factory ConfigurationHistorySeries.fromJson(Map<String, dynamic> json) {
    return ConfigurationHistorySeries(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      valueType: json['value_type']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      arrayIdField: json['array_id_field']?.toString(),
      validField: json['valid_field']?.toString(),
      axis: json['axis'] is Map
          ? ConfigurationHistoryAxis.fromJson(
              (json['axis'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  final String id;
  final String title;
  final String path;
  final String valueType;
  final String unit;
  final String? arrayIdField;
  final String? validField;
  final ConfigurationHistoryAxis? axis;
}
