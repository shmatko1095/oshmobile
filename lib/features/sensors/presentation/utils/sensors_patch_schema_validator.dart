import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/contracts/runtime_json_schema_validator.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';

class SensorsPatchSchemaValidator {
  final Map<String, dynamic>? _patchSchema;

  const SensorsPatchSchemaValidator._(this._patchSchema);

  factory SensorsPatchSchemaValidator.fromSnapshot(DeviceSnapshot snapshot) {
    final bundle = snapshot.details.data;
    if (bundle == null) {
      return const SensorsPatchSchemaValidator._(null);
    }

    final contracts = DeviceRuntimeContracts();
    contracts.applyRuntimeBundle(bundle);

    Map<String, dynamic>? patchSchema;
    try {
      patchSchema = contracts.sensors.patchSchema;
    } catch (_) {
      patchSchema = null;
    }

    return SensorsPatchSchemaValidator._(patchSchema);
  }

  bool get canValidate => _patchSchema != null;

  SensorRenameConstraints? get renameConstraints {
    final nameSchema = _renameNameSchema();
    if (nameSchema == null) return null;

    final minLength = _asInt(nameSchema['minLength']);
    final maxLength = _asInt(nameSchema['maxLength']);
    final pattern = _asString(nameSchema['pattern']);
    if (minLength == null && maxLength == null && pattern == null) {
      return null;
    }

    return SensorRenameConstraints(
      minLength: minLength,
      maxLength: maxLength,
      pattern: pattern,
    );
  }

  SensorCalibrationConstraints? get tempCalibrationConstraints {
    final valueSchema = _tempCalibrationValueSchema();
    if (valueSchema == null) return null;

    final min = _asDouble(valueSchema['minimum']);
    final max = _asDouble(valueSchema['maximum']);
    if (min == null || max == null) return null;

    final stepRaw = _asDouble(valueSchema['multipleOf']);
    final step = (stepRaw != null && stepRaw > 0) ? stepRaw : null;

    return SensorCalibrationConstraints(
      min: min,
      max: max,
      step: step,
    );
  }

  bool validateRename({
    required String id,
    required String name,
  }) {
    return _validatePatch(SensorsPatchRename(id: id, name: name));
  }

  bool validateTempCalibration({
    required String id,
    required double value,
  }) {
    return _validatePatch(
      SensorsPatchSetTempCalibration(id: id, value: value),
    );
  }

  bool _validatePatch(SensorsPatch patch) {
    final schema = _patchSchema;
    if (schema == null) return true;

    return RuntimeJsonSchemaValidator.validate(
      value: patch.toJson(),
      schema: schema,
    );
  }

  Map<String, dynamic>? _tempCalibrationValueSchema() {
    final patch = _patchSchema;
    if (patch == null) return null;

    final properties = _asMap(patch['properties']);
    final calibrationPatch = _asMap(properties['set_temp_calibration']);
    final calibrationProps = _asMap(calibrationPatch['properties']);
    final valueSchema = _asMap(calibrationProps['value']);

    if (valueSchema.isEmpty) return null;
    return valueSchema;
  }

  Map<String, dynamic>? _renameNameSchema() {
    final patch = _patchSchema;
    if (patch == null) return null;

    final properties = _asMap(patch['properties']);
    final renamePatch = _asMap(properties['rename']);
    final renameProps = _asMap(renamePatch['properties']);
    final nameSchema = _asMap(renameProps['name']);

    if (nameSchema.isEmpty) return null;
    return nameSchema;
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  double? _asDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return null;
  }

  int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return null;
  }

  String? _asString(dynamic raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }
}

class SensorRenameConstraints {
  final int? minLength;
  final int? maxLength;
  final String? pattern;

  const SensorRenameConstraints({
    required this.minLength,
    required this.maxLength,
    required this.pattern,
  });

  bool get isUsable =>
      minLength != null || maxLength != null || pattern != null;
}

class SensorCalibrationConstraints {
  final double min;
  final double max;
  final double? step;

  const SensorCalibrationConstraints({
    required this.min,
    required this.max,
    required this.step,
  });

  bool get isUsable => min < max;

  int? get divisions {
    final s = step;
    if (s == null || s <= 0) return null;
    final raw = (max - min) / s;
    if (raw <= 0) return null;
    return raw.round();
  }

  double snap(double value) {
    final clamped = value.clamp(min, max).toDouble();
    final s = step;
    if (s == null || s <= 0) return clamped;

    final snapped = min + (((clamped - min) / s).round() * s);
    return snapped.clamp(min, max).toDouble();
  }
}
