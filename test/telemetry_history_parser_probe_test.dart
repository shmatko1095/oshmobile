import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oshmobile/core/network/mobile/mobile_api_client.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source_impl.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';

class _FakeMobileApiClient extends MobileApiClient {
  _FakeMobileApiClient(this._payload)
      : super(
          client: ChopperClient(baseUrl: Uri.parse('https://example.org')),
        );

  final Map<String, dynamic> _payload;

  @override
  Future<Map<String, dynamic>> getMyDeviceTelemetryHistoryRaw({
    required String serial,
    required List<String> seriesKeys,
    required DateTime from,
    required DateTime to,
    String resolution = 'auto',
    String apiVersion = 'v1',
  }) async {
    return _payload;
  }
}

void main() {
  test('parses numeric epoch bucket_start and keeps points', () async {
    final payload = <String, dynamic>{
      'device_id': 'ff07dce5-c7fe-4f18-b944-c0979f3a5822',
      'serial': '9C139EB02CDC',
      'resolution': '5m',
      'from': 1773433120.445598,
      'to': 1773519520.445598,
      'series': [
        {
          'series_key': 'climate_sensors.floor.temp',
          'points': [
            {
              'bucket_start': 1773516600.0,
              'samples_count': 16,
              'min_value': 26.3,
              'max_value': 29.4,
              'avg_value': 28.141249999999996,
              'last_numeric_value': 29.4,
              'reference_sensor_id': 'pcb',
            },
            {
              'bucket_start': 1773516900.0,
              'samples_count': 5,
              'min_value': 27.94,
              'max_value': 28.45,
              'avg_value': 28.204,
              'last_numeric_value': 28.25,
            },
          ],
        },
      ],
    };

    final source = TelemetryHistoryRemoteDataSourceImpl(
      mobileApiClient: _FakeMobileApiClient(payload),
    );

    final series = await source.getSeries(
      serial: '9C139EB02CDC',
      query: TelemetryHistoryQuery(
        seriesKey: 'climate_sensors.floor.temp',
        from: DateTime.utc(2026, 3, 13, 20, 18, 40),
        to: DateTime.utc(2026, 3, 14, 20, 18, 40),
      ),
    );

    expect(series.points, hasLength(2));
    expect(series.points.first.avgValue, closeTo(28.141249999999996, 0.000001));
    expect(series.points.first.bucketStart, DateTime.utc(2026, 3, 14, 19, 30));
    expect(series.points.first.referenceSensorId, 'pcb');
  });

  test('parses numeric fields delivered as strings', () async {
    final payload = <String, dynamic>{
      'device_id': 'ff07dce5-c7fe-4f18-b944-c0979f3a5822',
      'serial': '9C139EB02CDC',
      'resolution': '5m',
      'from': '1773433120.445598000',
      'to': '1773519520.445598000',
      'series': [
        {
          'series_key': 'climate_sensors.floor.temp',
          'points': [
            {
              'bucket_start': '1773516600.000000000',
              'samples_count': ' 16 ',
              'min_value': ' 26.3 ',
              'max_value': '29.4',
              'avg_value': '28.141249999999996',
              'last_numeric_value': '29.4',
            },
          ],
        },
      ],
    };

    final source = TelemetryHistoryRemoteDataSourceImpl(
      mobileApiClient: _FakeMobileApiClient(payload),
    );

    final series = await source.getSeries(
      serial: '9C139EB02CDC',
      query: TelemetryHistoryQuery(
        seriesKey: 'climate_sensors.floor.temp',
        from: DateTime.utc(2026, 3, 13, 20, 18, 40),
        to: DateTime.utc(2026, 3, 14, 20, 18, 40),
      ),
    );

    expect(series.points, hasLength(1));
    expect(series.points.first.samplesCount, 16);
    expect(series.points.first.minValue, 26.3);
    expect(series.points.first.avgValue, closeTo(28.141249999999996, 0.000001));
    expect(series.points.first.bucketStart, DateTime.utc(2026, 3, 14, 19, 30));
  });
}
