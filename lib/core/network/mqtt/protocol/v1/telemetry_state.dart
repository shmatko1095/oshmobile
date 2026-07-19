import 'package:oshmobile/core/network/mqtt/protocol/v1/climate_sensor_telemetry.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/telemetry_decode_issue.dart';

final class TelemetryState {
  final List<ClimateSensorTelemetry> climateSensors;
  final bool? heaterEnabled;
  final Map<String, dynamic> raw;

  const TelemetryState({
    required this.climateSensors,
    required this.heaterEnabled,
    this.raw = const <String, dynamic>{},
  });

  static TelemetryState fromJson(
    Map<String, dynamic> json, {
    required void Function(TelemetryDecodeIssue issue) onIssue,
  }) {
    final sanitizedRaw = Map<String, dynamic>.from(json)..remove('load_factor');
    final sensors = <ClimateSensorTelemetry>[];
    final sensorsRaw = json['climate_sensors'];

    if (sensorsRaw is List) {
      for (var index = 0; index < sensorsRaw.length; index += 1) {
        final item = sensorsRaw[index];
        if (item is! Map) {
          onIssue(
            TelemetryDecodeIssue(
              path: 'climate_sensors[$index]',
              reason: 'expected_object',
            ),
          );
          continue;
        }
        final parsed = ClimateSensorTelemetry.fromJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
          path: 'climate_sensors[$index]',
          onIssue: onIssue,
        );
        if (parsed != null) sensors.add(parsed);
      }
    } else {
      onIssue(
        const TelemetryDecodeIssue(
          path: 'climate_sensors',
          reason: 'expected_array',
        ),
      );
    }

    final heaterRaw = json['heater_enabled'];
    final heaterEnabled = heaterRaw is bool ? heaterRaw : null;
    if (heaterRaw != null && heaterEnabled == null) {
      onIssue(
        const TelemetryDecodeIssue(
          path: 'heater_enabled',
          reason: 'expected_boolean',
        ),
      );
    }
    sanitizedRaw['climate_sensors'] = <Map<String, dynamic>>[
      for (final sensor in sensors) sensor.toJson(),
    ];
    if (heaterEnabled == null) {
      sanitizedRaw.remove('heater_enabled');
    } else {
      sanitizedRaw['heater_enabled'] = heaterEnabled;
    }

    return TelemetryState(
      climateSensors: List<ClimateSensorTelemetry>.unmodifiable(sensors),
      heaterEnabled: heaterEnabled,
      raw: Map<String, dynamic>.unmodifiable(sanitizedRaw),
    );
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(raw);
}
