# AGENTS.md

## Thermostat Sensor Notes

- Thermostat dashboards read live values from `DeviceSnapshot.controlState`, not directly from raw MQTT maps.
- `ControlStateResolver` builds `climateSensors` from the runtime model configuration collection mappings.
- `climateSensors` is assembled from multiple domains: telemetry can provide temperature before sensors metadata provides `name`, `kind`, and `ref`.
- Do not reorder `climateSensors` to prioritize the reference sensor. Keep incoming/stabilized order and move carousel/page state to the reference sensor instead.
- In `TemperatureMinimalPanel`, handle `ref` as late-arriving metadata on cold boot; do not lock initial carousel state permanently before `ref` appears.
- `TemperatureMinimalPanel` treats `temp_valid` as fresh/control-safe and `temp_stale` as display-only. A stale temperature may be shown with a yellow marker, but must not be treated as fresh.
- Sensor calibration is intentionally not exposed in the mobile app. Do not reintroduce `SensorCalibrationPage`, `setTempCalibration`, `SensorsPatchSetTempCalibration`, or `SensorMeta.tempCalibration*` without an explicit product decision.

## Checks

- Format touched Dart files with `dart format`.
- Prefer targeted widget/unit tests first, then `flutter test` and `flutter analyze` when practical.
