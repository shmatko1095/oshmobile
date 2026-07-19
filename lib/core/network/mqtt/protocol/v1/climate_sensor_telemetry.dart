import 'package:oshmobile/core/network/mqtt/protocol/v1/telemetry_decode_issue.dart';

final class ClimateSensorTelemetry {
  final String id;
  final bool? tempValid;
  final bool? tempStale;
  final bool? humidityValid;
  final double? temp;
  final double? humidity;

  const ClimateSensorTelemetry({
    required this.id,
    required this.tempValid,
    required this.tempStale,
    required this.humidityValid,
    required this.temp,
    required this.humidity,
  });

  static ClimateSensorTelemetry? fromJson(
    Map<String, dynamic> json, {
    required String path,
    required void Function(TelemetryDecodeIssue issue) onIssue,
  }) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      onIssue(
        TelemetryDecodeIssue(
          path: '$path.id',
          reason: 'missing_sensor_identity',
        ),
      );
      return null;
    }

    final tempValid = _optionalBool(
      json,
      key: 'temp_valid',
      path: path,
      onIssue: onIssue,
    );
    final tempStale = _optionalBool(
      json,
      key: 'temp_stale',
      path: path,
      onIssue: onIssue,
    );
    final humidityValid = _optionalBool(
      json,
      key: 'humidity_valid',
      path: path,
      onIssue: onIssue,
    );
    var temp = _finiteDouble(json['temp']);
    var humidity = _finiteDouble(json['humidity']);

    final temperatureDisplayable = tempValid == true || tempStale == true;
    if (temperatureDisplayable && temp == null) {
      onIssue(
        TelemetryDecodeIssue(
          path: '$path.temp',
          reason: 'missing_value_for_valid_field',
        ),
      );
    } else if (!temperatureDisplayable && temp != null) {
      onIssue(
        TelemetryDecodeIssue(
          path: '$path.temp',
          reason: 'value_present_while_invalid',
        ),
      );
      temp = null;
    }

    if (humidityValid == true && humidity == null) {
      onIssue(
        TelemetryDecodeIssue(
          path: '$path.humidity',
          reason: 'missing_value_for_valid_field',
        ),
      );
    } else if (humidityValid != true && humidity != null) {
      onIssue(
        TelemetryDecodeIssue(
          path: '$path.humidity',
          reason: 'value_present_while_invalid',
        ),
      );
      humidity = null;
    }

    return ClimateSensorTelemetry(
      id: id,
      tempValid: tempValid,
      tempStale: tempStale,
      humidityValid: humidityValid,
      temp: temp,
      humidity: humidity,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        if (tempValid != null) 'temp_valid': tempValid,
        if (tempStale != null) 'temp_stale': tempStale,
        if (humidityValid != null) 'humidity_valid': humidityValid,
        if (temp != null) 'temp': temp,
        if (humidity != null) 'humidity': humidity,
      };
}

double? _finiteDouble(dynamic raw) {
  if (raw is! num || !raw.isFinite) return null;
  return raw.toDouble();
}

bool? _optionalBool(
  Map<String, dynamic> json, {
  required String key,
  required String path,
  required void Function(TelemetryDecodeIssue issue) onIssue,
}) {
  final raw = json[key];
  if (raw == null) return null;
  if (raw is bool) return raw;
  onIssue(
    TelemetryDecodeIssue(
      path: '$path.$key',
      reason: 'expected_boolean',
    ),
  );
  return null;
}
