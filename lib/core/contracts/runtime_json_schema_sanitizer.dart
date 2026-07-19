import 'package:oshmobile/core/contracts/runtime_json_schema_validator.dart';

typedef RuntimeJsonSchemaIssueSink = void Function(
  String path,
  String reason,
);

final class RuntimeJsonSchemaSanitizer {
  RuntimeJsonSchemaSanitizer._();

  static dynamic sanitize({
    required dynamic value,
    required Map<String, dynamic> schema,
    required RuntimeJsonSchemaIssueSink onIssue,
    String path = r'$',
  }) {
    return _sanitizeValue(
      value: value,
      schema: schema,
      onIssue: onIssue,
      path: path,
    );
  }

  static dynamic _sanitizeValue({
    required dynamic value,
    required Map<String, dynamic> schema,
    required RuntimeJsonSchemaIssueSink onIssue,
    required String path,
  }) {
    final type = schema['type'];
    if (type is List) {
      if (value is Map && type.contains('object')) {
        return _sanitizeValue(
          value: value,
          schema: <String, dynamic>{...schema, 'type': 'object'},
          onIssue: onIssue,
          path: path,
        );
      }
      if (value is List && type.contains('array')) {
        return _sanitizeValue(
          value: value,
          schema: <String, dynamic>{...schema, 'type': 'array'},
          onIssue: onIssue,
          path: path,
        );
      }
    }
    if (type == 'object' || (value is Map && _usesObjectKeywords(schema))) {
      if (value is! Map) {
        onIssue(path, 'expected_object');
        return _discarded;
      }
      return _sanitizeObject(
        value: value,
        schema: schema,
        onIssue: onIssue,
        path: path,
      );
    }

    if (type == 'array') {
      if (value is! List) {
        onIssue(path, 'expected_array');
        return _discarded;
      }
      return _sanitizeArray(
        value: value,
        schema: schema,
        onIssue: onIssue,
        path: path,
      );
    }

    if (!RuntimeJsonSchemaValidator.validate(value: value, schema: schema)) {
      onIssue(path, _primitiveIssueReason(value: value, type: type));
      return _discarded;
    }

    return value;
  }

  static Map<String, dynamic> _sanitizeObject({
    required Map<dynamic, dynamic> value,
    required Map<String, dynamic> schema,
    required RuntimeJsonSchemaIssueSink onIssue,
    required String path,
  }) {
    final object = value.map(
      (key, child) => MapEntry(key.toString(), child),
    );
    final properties = _asMap(schema['properties']);
    final requiredKeys = _asStringSet(schema['required']);
    final sanitized = <String, dynamic>{};

    for (final key in requiredKeys) {
      if (!object.containsKey(key)) {
        onIssue(_propertyPath(path, key), 'missing_required_field');
      }
    }

    for (final entry in object.entries) {
      final childSchema = properties[entry.key];
      if (childSchema is! Map) {
        // Unknown fields are retained for forward compatibility. Typed readers
        // decide whether and when they can consume them.
        sanitized[entry.key] = entry.value;
        continue;
      }

      final child = _sanitizeValue(
        value: entry.value,
        schema: _asMap(childSchema),
        onIssue: onIssue,
        path: _propertyPath(path, entry.key),
      );
      if (!identical(child, _discarded)) {
        sanitized[entry.key] = child;
      }
    }

    return sanitized;
  }

  static List<dynamic> _sanitizeArray({
    required List<dynamic> value,
    required Map<String, dynamic> schema,
    required RuntimeJsonSchemaIssueSink onIssue,
    required String path,
  }) {
    final itemSchema = schema['items'];
    if (itemSchema is! Map) return List<dynamic>.from(value);

    final sanitized = <dynamic>[];
    for (var index = 0; index < value.length; index += 1) {
      final child = _sanitizeValue(
        value: value[index],
        schema: _asMap(itemSchema),
        onIssue: onIssue,
        path: '$path[$index]',
      );
      if (!identical(child, _discarded)) {
        sanitized.add(child);
      }
    }
    return sanitized;
  }

  static String _primitiveIssueReason({
    required dynamic value,
    required dynamic type,
  }) {
    if (type == 'boolean' && value is! bool) return 'expected_boolean';
    if ((type == 'number' || type == 'integer') && value is! num) {
      return type == 'integer' ? 'expected_integer' : 'expected_number';
    }
    if (type == 'string' && value is! String) return 'expected_string';
    if (type == 'null' && value != null) return 'expected_null';
    return 'schema_constraint_failed';
  }

  static bool _usesObjectKeywords(Map<String, dynamic> schema) {
    return schema.containsKey('required') ||
        schema.containsKey('properties') ||
        schema.containsKey('additionalProperties');
  }

  static String _propertyPath(String path, String property) {
    return path == r'$' ? property : '$path.$property';
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  static Set<String> _asStringSet(dynamic raw) {
    if (raw is! List) return const <String>{};
    return raw.map((item) => item.toString()).toSet();
  }
}

const Object _discarded = Object();
