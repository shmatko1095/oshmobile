import 'package:oshmobile/core/contracts/runtime_json_schema_validator.dart';

class TelemetryPayloadValidator {
  final Map<String, dynamic>? _stateSchema;

  const TelemetryPayloadValidator({
    Map<String, dynamic>? stateSchema,
  }) : _stateSchema = stateSchema;

  bool validateStatePayload(Map<String, dynamic> data) {
    final schema = _stateSchema;
    if (schema == null) return false;
    return RuntimeJsonSchemaValidator.validate(
      value: data,
      schema: _allowUnknownFields(schema),
    );
  }

  Map<String, dynamic> _allowUnknownFields(Map<String, dynamic> schema) {
    return _copySchemaValue(schema) as Map<String, dynamic>;
  }

  dynamic _copySchemaValue(dynamic value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((key, child) {
        final normalizedKey = key.toString();
        if (normalizedKey == 'additionalProperties' && child == false) {
          return;
        }
        out[normalizedKey] = _copySchemaValue(child);
      });
      return out;
    }
    if (value is List) {
      return [for (final item in value) _copySchemaValue(item)];
    }
    return value;
  }
}
