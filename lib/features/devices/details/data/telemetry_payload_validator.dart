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
      schema: schema,
    );
  }
}
