class RuntimeJsonSchemaValidator {
  static bool validate({
    required dynamic value,
    required Map<String, dynamic> schema,
  }) {
    return _validateValue(
      value: value,
      schema: schema,
    );
  }

  static bool _validateValue({
    required dynamic value,
    required Map<String, dynamic> schema,
  }) {
    if (schema.containsKey('const')) {
      if (value != schema['const']) return false;
    }

    final enumValues = schema['enum'];
    if (enumValues is List && enumValues.isNotEmpty) {
      var match = false;
      for (final candidate in enumValues) {
        if (value == candidate) {
          match = true;
          break;
        }
      }
      if (!match) return false;
    }

    final notSchema = schema['not'];
    if (notSchema is Map) {
      if (_validateValue(
        value: value,
        schema: _asMap(notSchema),
      )) {
        return false;
      }
    }

    final ifSchema = schema['if'];
    if (ifSchema is Map) {
      final ifMatches = _validateValue(
        value: value,
        schema: _asMap(ifSchema),
      );
      final thenSchema = schema['then'];
      final elseSchema = schema['else'];
      if (ifMatches && thenSchema is Map) {
        if (!_validateValue(value: value, schema: _asMap(thenSchema))) {
          return false;
        }
      }
      if (!ifMatches && elseSchema is Map) {
        if (!_validateValue(value: value, schema: _asMap(elseSchema))) {
          return false;
        }
      }
    }

    final allOf = schema['allOf'];
    if (allOf is List) {
      for (final part in allOf) {
        if (part is! Map) continue;
        if (!_validateValue(
          value: value,
          schema: _asMap(part),
        )) {
          return false;
        }
      }
    }

    final oneOf = schema['oneOf'];
    if (oneOf is List && oneOf.isNotEmpty) {
      var matches = 0;
      for (final part in oneOf) {
        if (part is! Map) continue;
        if (_validateValue(
          value: value,
          schema: _asMap(part),
        )) {
          matches += 1;
        }
      }
      if (matches != 1) return false;
    }

    final anyOf = schema['anyOf'];
    if (anyOf is List && anyOf.isNotEmpty) {
      var match = false;
      for (final part in anyOf) {
        if (part is! Map) continue;
        if (_validateValue(
          value: value,
          schema: _asMap(part),
        )) {
          match = true;
          break;
        }
      }
      if (!match) return false;
    }

    final type = schema['type'];
    if (type is String) {
      if (!_validateByType(
        type: type,
        value: value,
        schema: schema,
      )) {
        return false;
      }
    } else if (type is List && type.isNotEmpty) {
      var match = false;
      for (final raw in type) {
        if (raw is! String) continue;
        if (_validateByType(
          type: raw,
          value: value,
          schema: schema,
        )) {
          match = true;
          break;
        }
      }
      if (!match) return false;
    }

    return true;
  }

  static bool _validateByType({
    required String type,
    required dynamic value,
    required Map<String, dynamic> schema,
  }) {
    switch (type) {
      case 'object':
        return _validateObject(
          value: value,
          schema: schema,
        );
      case 'array':
        return _validateArray(
          value: value,
          schema: schema,
        );
      case 'string':
        return _validateString(
          value: value,
          schema: schema,
        );
      case 'integer':
        return _validateNumber(
          value: value,
          schema: schema,
          integerOnly: true,
        );
      case 'number':
        return _validateNumber(
          value: value,
          schema: schema,
          integerOnly: false,
        );
      case 'boolean':
        return value is bool;
      case 'null':
        return value == null;
      default:
        return true;
    }
  }

  static bool _validateObject({
    required dynamic value,
    required Map<String, dynamic> schema,
  }) {
    if (value is! Map) return false;
    final object = _asMap(value);

    final properties = _asMap(schema['properties']);
    final requiredKeys = _asStringSet(schema['required']);
    for (final key in requiredKeys) {
      if (!object.containsKey(key)) return false;
    }

    final additionalProperties = schema['additionalProperties'];
    for (final entry in object.entries) {
      final key = entry.key;
      final childSchema = properties[key];
      if (childSchema is Map) {
        if (!_validateValue(
          value: entry.value,
          schema: _asMap(childSchema),
        )) {
          return false;
        }
        continue;
      }

      if (additionalProperties == false) {
        return false;
      }
      if (additionalProperties is Map) {
        if (!_validateValue(
          value: entry.value,
          schema: _asMap(additionalProperties),
        )) {
          return false;
        }
      }
    }

    return true;
  }

  static bool _validateArray({
    required dynamic value,
    required Map<String, dynamic> schema,
  }) {
    if (value is! List) return false;

    final minItems = _asNum(schema['minItems']);
    if (minItems != null && value.length < minItems.toInt()) return false;
    final maxItems = _asNum(schema['maxItems']);
    if (maxItems != null && value.length > maxItems.toInt()) return false;

    final uniqueItems = schema['uniqueItems'];
    if (uniqueItems == true) {
      for (var i = 0; i < value.length; i++) {
        for (var j = i + 1; j < value.length; j++) {
          if (value[i] == value[j]) return false;
        }
      }
    }

    final itemSchema = schema['items'];
    if (itemSchema is Map) {
      for (final item in value) {
        if (!_validateValue(
          value: item,
          schema: _asMap(itemSchema),
        )) {
          return false;
        }
      }
    }

    return true;
  }

  static bool _validateString({
    required dynamic value,
    required Map<String, dynamic> schema,
  }) {
    if (value is! String) return false;

    final minLength = _asNum(schema['minLength']);
    if (minLength != null && value.length < minLength.toInt()) return false;
    final maxLength = _asNum(schema['maxLength']);
    if (maxLength != null && value.length > maxLength.toInt()) return false;

    final pattern = schema['pattern'];
    if (pattern is String && pattern.isNotEmpty) {
      final re = RegExp(pattern);
      if (!re.hasMatch(value)) return false;
    }

    return true;
  }

  static bool _validateNumber({
    required dynamic value,
    required Map<String, dynamic> schema,
    required bool integerOnly,
  }) {
    if (value is! num) return false;
    if (integerOnly && value % 1 != 0) return false;

    final minimum = _asNum(schema['minimum']);
    if (minimum != null && value < minimum) return false;
    final maximum = _asNum(schema['maximum']);
    if (maximum != null && value > maximum) return false;

    final exclusiveMinimum = _asNum(schema['exclusiveMinimum']);
    if (exclusiveMinimum != null && value <= exclusiveMinimum) return false;
    final exclusiveMaximum = _asNum(schema['exclusiveMaximum']);
    if (exclusiveMaximum != null && value >= exclusiveMaximum) return false;

    final multipleOf = _asNum(schema['multipleOf']);
    if (multipleOf != null && multipleOf != 0) {
      final ratio = value / multipleOf;
      if ((ratio - ratio.round()).abs() > 1e-9) return false;
    }

    return true;
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
    return raw
        .map((value) => value?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  static num? _asNum(dynamic value) {
    if (value is num) return value;
    return null;
  }
}
