import 'package:flutter/material.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/core/profile/control_binding_registry.dart';
import 'package:oshmobile/features/schedule/data/schedule_jsonrpc_codec.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/utils/schedule_point_resolver.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';

class ControlStateResolver {
  const ControlStateResolver();

  Map<String, dynamic> resolveAll({
    required ControlBindingRegistry registry,
    required Iterable<String> controlIds,
    TelemetryState? telemetry,
    SensorsState? sensors,
    CalendarSnapshot? schedule,
    SettingsSnapshot? settings,
    Map<String, dynamic>? deviceState,
    Map<String, dynamic>? diagState,
  }) {
    final out = <String, dynamic>{};
    for (final controlId in controlIds) {
      if (!registry.canRead(controlId)) continue;
      final binding = registry.readBinding(controlId);
      if (binding == null) continue;
      final value = _resolveBinding(
        binding,
        telemetry: telemetry,
        sensors: sensors,
        schedule: schedule,
        settings: settings,
        deviceState: deviceState,
        diagState: diagState,
      );
      if (value != null) {
        out[controlId] = value;
      }
    }
    _injectDerivedControls(
      out,
      telemetry: telemetry,
      sensors: sensors,
      schedule: schedule,
    );
    return out;
  }

  dynamic _resolveBinding(
    dynamic binding, {
    required TelemetryState? telemetry,
    required SensorsState? sensors,
    required CalendarSnapshot? schedule,
    required SettingsSnapshot? settings,
    required Map<String, dynamic>? deviceState,
    required Map<String, dynamic>? diagState,
  }) {
    switch (binding.kind) {
      case 'state_snapshot':
      case 'collection_state':
        final snapshot = _snapshotForDomain(
          binding.domain,
          telemetry: telemetry,
          sensors: sensors,
          schedule: schedule,
          settings: settings,
          deviceState: deviceState,
          diagState: diagState,
        );
        return _readPath(snapshot, binding.path);

      case 'reference_sensor_field':
        return _resolveReferenceSensorField(
          sensors: sensors,
          telemetry: telemetry,
          field: binding.field,
          validField: binding.validField,
        );

      case 'reference_sensor_id':
        return _referenceSensorMeta(sensors)?.id;

      case 'joined_climate_sensor_cards':
        return _joinClimateSensors(sensors: sensors, telemetry: telemetry);

      case 'schedule_current_target':
        final point = schedule == null ? null : resolveCurrentPoint(schedule);
        return point?.temp;

      case 'schedule_next_target':
        final point = schedule == null ? null : resolveNextPoint(schedule);
        if (point == null) return null;
        return <String, dynamic>{
          'temp': point.temp,
          'hour': point.time.hour,
          'minute': point.time.minute,
        };
    }

    return null;
  }

  void _injectDerivedControls(
    Map<String, dynamic> out, {
    required TelemetryState? telemetry,
    required SensorsState? sensors,
    required CalendarSnapshot? schedule,
  }) {
    out['telemetry_climate_sensors'] = _joinClimateSensors(
      sensors: sensors,
      telemetry: telemetry,
    );

    final referenceSensor = _referenceSensorMeta(sensors);
    if (referenceSensor != null) {
      out['reference_sensor_id'] = referenceSensor.id;
    }

    final ambientTemp = _resolveReferenceSensorField(
      sensors: sensors,
      telemetry: telemetry,
      field: 'temp',
      validField: 'temp_valid',
    );
    if (ambientTemp != null) {
      out['ambient_temperature'] = ambientTemp;
    }

    final ambientHumidity = _resolveReferenceSensorField(
      sensors: sensors,
      telemetry: telemetry,
      field: 'humidity',
      validField: 'humidity_valid',
    );
    if (ambientHumidity != null) {
      out['ambient_humidity'] = ambientHumidity;
    }

    final currentTarget =
        schedule == null ? null : resolveCurrentPoint(schedule);
    if (currentTarget != null) {
      out['schedule_current_target_temp'] = currentTarget.temp;
    }

    final nextTarget = schedule == null ? null : resolveNextPoint(schedule);
    if (nextTarget != null) {
      out['schedule_next_target_temp'] = <String, dynamic>{
        'temp': nextTarget.temp,
        'hour': nextTarget.time.hour,
        'minute': nextTarget.time.minute,
      };
    }
  }

  dynamic _resolveReferenceSensorField({
    required SensorsState? sensors,
    required TelemetryState? telemetry,
    required String? field,
    required String? validField,
  }) {
    final refMeta = _referenceSensorMeta(sensors);
    if (refMeta == null || telemetry == null || field == null) return null;

    ClimateSensorTelemetry? climate;
    for (final item in telemetry.climateSensors) {
      if (item.id == refMeta.id) {
        climate = item;
        break;
      }
    }
    if (climate == null) return null;

    if (validField == 'temp_valid' && !climate.tempValid) return null;
    if (validField == 'humidity_valid' && !climate.humidityValid) return null;

    switch (field) {
      case 'temp':
        return climate.temp;
      case 'humidity':
        return climate.humidity;
    }
    return null;
  }

  List<Map<String, dynamic>> _joinClimateSensors({
    required SensorsState? sensors,
    required TelemetryState? telemetry,
  }) {
    if (sensors == null) return const <Map<String, dynamic>>[];

    final telemetryById = <String, ClimateSensorTelemetry>{
      for (final item
          in telemetry?.climateSensors ?? const <ClimateSensorTelemetry>[])
        item.id: item,
    };

    return sensors.items.map((meta) {
      final live = telemetryById[meta.id];
      return <String, dynamic>{
        'id': meta.id,
        'name': meta.name,
        'kind': meta.kind,
        'ref': meta.ref,
        'temp_valid': live?.tempValid ?? false,
        'humidity_valid': live?.humidityValid ?? false,
        if (live?.temp != null) 'temp': live!.temp,
        if (live?.humidity != null) 'humidity': live!.humidity,
      };
    }).toList(growable: false);
  }

  SensorMeta? _referenceSensorMeta(SensorsState? sensors) {
    if (sensors == null) return null;
    for (final item in sensors.items) {
      if (item.ref) return item;
    }
    return sensors.items.isEmpty ? null : sensors.items.first;
  }

  Map<String, dynamic>? _snapshotForDomain(
    String? domain, {
    required TelemetryState? telemetry,
    required SensorsState? sensors,
    required CalendarSnapshot? schedule,
    required SettingsSnapshot? settings,
    required Map<String, dynamic>? deviceState,
    required Map<String, dynamic>? diagState,
  }) {
    switch (domain) {
      case 'telemetry':
        if (telemetry == null) return null;
        return <String, dynamic>{
          'climate_sensors': [
            for (final item in telemetry.climateSensors)
              <String, dynamic>{
                'id': item.id,
                'temp_valid': item.tempValid,
                'humidity_valid': item.humidityValid,
                if (item.temp != null) 'temp': item.temp,
                if (item.humidity != null) 'humidity': item.humidity,
              },
          ],
          'heater_enabled': telemetry.heaterEnabled,
          'load_factor': telemetry.loadFactor,
        };
      case 'sensors':
        return sensors?.toJson();
      case 'schedule':
        return schedule == null
            ? null
            : ScheduleJsonRpcCodec.encodeBody(schedule);
      case 'settings':
        return settings?.toJson();
      case 'device':
        return deviceState;
      case 'diag':
        return diagState;
    }
    return null;
  }

  dynamic _readPath(Map<String, dynamic>? source, String? path) {
    if (source == null || path == null || path.isEmpty) return null;
    dynamic current = source;
    for (final part in path.split('.')) {
      if (current is! Map) return null;
      if (!current.containsKey(part)) return null;
      current = current[part];
    }
    return current;
  }

  TimeOfDay? nextTargetTime(dynamic raw) {
    if (raw is! Map) return null;
    final hour = raw['hour'] as int?;
    final minute = raw['minute'] as int?;
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
