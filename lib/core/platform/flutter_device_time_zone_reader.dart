import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:oshmobile/core/contracts/device_time_zone_reader.dart';
import 'package:oshmobile/core/logging/app_log.dart';

class FlutterDeviceTimeZoneReader implements DeviceTimeZoneReader {
  FlutterDeviceTimeZoneReader({
    Future<String> Function()? identifierLoader,
  }) : _identifierLoader = identifierLoader ?? _loadPlatformIdentifier;

  static const String fallbackTimeZone = 'UTC';

  final Future<String> Function() _identifierLoader;

  @override
  Future<String> readIanaTimeZone() async {
    try {
      final identifier = (await _identifierLoader()).trim();
      if (identifier.isEmpty) {
        throw const FormatException('Device time zone identifier is empty.');
      }
      return identifier;
    } catch (error) {
      AppLog.warn(
        'Unable to read the device IANA time zone; using '
        '$fallbackTimeZone. Error: $error',
      );
      return fallbackTimeZone;
    }
  }

  static Future<String> _loadPlatformIdentifier() async {
    final timeZone = await FlutterTimezone.getLocalTimezone();
    return timeZone.identifier;
  }
}
