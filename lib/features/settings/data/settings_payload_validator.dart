import 'package:oshmobile/core/contracts/runtime_json_schema_validator.dart';

class SettingsPayloadValidator {
  final Map<String, dynamic>? _stateSchema;
  final Map<String, dynamic>? _setSchema;
  final Map<String, dynamic>? _patchSchema;

  const SettingsPayloadValidator({
    Map<String, dynamic>? stateSchema,
    Map<String, dynamic>? setSchema,
    Map<String, dynamic>? patchSchema,
  })  : _stateSchema = stateSchema,
        _setSchema = setSchema,
        _patchSchema = patchSchema;

  bool validateStatePayload(Map<String, dynamic> data) {
    final schema = _stateSchema ?? _setSchema ?? _patchSchema;
    if (schema == null) return false;
    return RuntimeJsonSchemaValidator.validate(
      value: data,
      schema: schema,
    );
  }

  bool validateSetPayload(Map<String, dynamic> data) {
    final schema = _setSchema ?? _stateSchema ?? _patchSchema;
    if (schema == null) return false;
    return RuntimeJsonSchemaValidator.validate(
      value: data,
      schema: schema,
    );
  }

  bool validatePatchPayload(Map<String, dynamic> data) {
    final schema = _patchSchema ?? _setSchema ?? _stateSchema;
    if (schema == null) return false;
    return RuntimeJsonSchemaValidator.validate(
      value: data,
      schema: schema,
    );
  }
}
