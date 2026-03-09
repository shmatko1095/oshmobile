import 'package:oshmobile/core/contracts/runtime_json_schema_validator.dart';

class DeviceStatePayloadValidator {
  final Map<String, dynamic>? _stateSchema;

  const DeviceStatePayloadValidator({
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
