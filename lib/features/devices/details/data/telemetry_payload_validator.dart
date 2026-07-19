import 'package:oshmobile/core/contracts/runtime_json_schema_validator.dart';
import 'package:oshmobile/core/contracts/runtime_json_schema_sanitizer.dart';

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

  Map<String, dynamic> sanitizeStatePayload(
    Map<String, dynamic> data, {
    required RuntimeJsonSchemaIssueSink onIssue,
  }) {
    final schema = _stateSchema;
    if (schema == null) {
      onIssue(r'$', 'runtime_schema_unavailable');
      return Map<String, dynamic>.from(data);
    }

    final sanitized = RuntimeJsonSchemaSanitizer.sanitize(
      value: data,
      schema: schema,
      onIssue: onIssue,
    );
    if (sanitized is Map<String, dynamic>) return sanitized;
    if (sanitized is Map) {
      return sanitized.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return const <String, dynamic>{};
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
