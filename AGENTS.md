# AGENTS.md

## Thermostat Sensor Notes

- Thermostat dashboards read live values from `DeviceSnapshot.controlState`, not directly from raw MQTT maps.
- `ControlStateResolver` builds `climateSensors` from the runtime model configuration collection mappings.
- `TemperatureMinimalPanel` treats `temp_valid` as fresh/control-safe and `temp_stale` as display-only. A stale temperature may be shown with a yellow marker, but must not be treated as fresh.
- Sensor calibration is intentionally not exposed in the mobile app. Do not reintroduce `SensorCalibrationPage`, `setTempCalibration`, `SensorsPatchSetTempCalibration`, or `SensorMeta.tempCalibration*` without an explicit product decision.

## Checks

- Format touched Dart files with `dart format`.
- Prefer targeted widget/unit tests first, then `flutter test` and `flutter analyze` when practical.
