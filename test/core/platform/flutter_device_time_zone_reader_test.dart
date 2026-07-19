import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/platform/flutter_device_time_zone_reader.dart';

void main() {
  test('returns the trimmed platform IANA identifier', () async {
    final reader = FlutterDeviceTimeZoneReader(
      identifierLoader: () async => ' Europe/Stockholm ',
    );

    expect(await reader.readIanaTimeZone(), 'Europe/Stockholm');
  });

  test('preserves an America/New_York IANA identifier', () async {
    final reader = FlutterDeviceTimeZoneReader(
      identifierLoader: () async => 'America/New_York',
    );

    expect(await reader.readIanaTimeZone(), 'America/New_York');
  });

  test('falls back to UTC when the platform lookup fails', () async {
    final reader = FlutterDeviceTimeZoneReader(
      identifierLoader: () async => throw StateError('unavailable'),
    );

    expect(await reader.readIanaTimeZone(), 'UTC');
  });

  test('falls back to UTC for an empty platform identifier', () async {
    final reader = FlutterDeviceTimeZoneReader(
      identifierLoader: () async => '  ',
    );

    expect(await reader.readIanaTimeZone(), 'UTC');
  });
}
