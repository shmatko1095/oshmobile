import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/claim_my_device_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/update_my_device_user_data_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source_impl.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_bucket.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';

class _FakeMobileV1Service extends MobileV1Service {
  _FakeMobileV1Service(this._payload);

  final Map<String, dynamic> _payload;

  @override
  Type get definitionType => MobileV1Service;

  @override
  Future<Response<dynamic>> createDemoSession() {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> ensureMySession() {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> getMyDeviceTelemetryHistory({
    required String serial,
    required String seriesKeys,
    required String from,
    required String to,
    String resolution = 'auto',
  }) async {
    return Response<dynamic>(http.Response('', 200), _payload);
  }

  @override
  Future<Response<dynamic>> getMyDeviceThermostatSetpointHistory({
    required String serial,
    required String from,
    required String to,
    String resolution = 'auto',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> getMyDeviceTelemetryAggregate({
    required String serial,
    required String seriesKeys,
    required String from,
    required String to,
    String resolution = 'auto',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> getMyDeviceEnergyUsage({
    required String serial,
    required String from,
    required String to,
    String? bucket,
    String? timezone,
  }) {
    return Future<Response<dynamic>>.value(
      Response<dynamic>(http.Response('', 200), _payload),
    );
  }

  @override
  Future<Response<dynamic>> getMyDeviceHeatingUsage({
    required String serial,
    required String from,
    required String to,
    String? bucket,
    String? timezone,
  }) {
    return Future<Response<dynamic>>.value(
      Response<dynamic>(http.Response('', 200), _payload),
    );
  }

  @override
  Future<Response<dynamic>> getClientPolicy({
    required String platform,
    required String appVersion,
    int? build,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> claimMyDevice({
    required String serial,
    required ClaimMyDeviceRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> getMyDevice({required String serial}) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> getMyDeviceUsers({required String serial}) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> listMyDevices() {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> requestMyAccountDeletion() {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> unassignMyDevice({required String serial}) {
    throw UnimplementedError();
  }

  @override
  Future<Response<dynamic>> updateMyDeviceUserData({
    required String serial,
    required UpdateMyDeviceUserDataRequest request,
  }) {
    throw UnimplementedError();
  }

  @override
  void updateClient(ChopperClient client) {}
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
              'sum_value': 450.26,
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
      mobileService: _FakeMobileV1Service(payload),
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
    expect(series.points.first.sumValue, closeTo(450.26, 0.000001));
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
              'sumValue': ' 450.26 ',
              'last_numeric_value': '29.4',
            },
          ],
        },
      ],
    };

    final source = TelemetryHistoryRemoteDataSourceImpl(
      mobileService: _FakeMobileV1Service(payload),
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
    expect(series.points.first.sumValue, closeTo(450.26, 0.000001));
    expect(series.points.first.bucketStart, DateTime.utc(2026, 3, 14, 19, 30));
  });

  test('does not substitute another series when requested key is missing',
      () async {
    final payload = <String, dynamic>{
      'device_id': 'ff07dce5-c7fe-4f18-b944-c0979f3a5822',
      'serial': '9C139EB02CDC',
      'resolution': '5m',
      'from': 1773433120.445598,
      'to': 1773519520.445598,
      'series': [
        {
          'series_key': 'climate_sensors.room.temp',
          'points': [
            {
              'bucket_start': 1773516600.0,
              'samples_count': 16,
              'avg_value': 28.1,
            },
          ],
        },
      ],
    };

    final source = TelemetryHistoryRemoteDataSourceImpl(
      mobileService: _FakeMobileV1Service(payload),
    );

    final series = await source.getSeries(
      serial: '9C139EB02CDC',
      query: TelemetryHistoryQuery(
        seriesKey: 'climate_sensors.floor.temp',
        from: DateTime.utc(2026, 3, 13, 20, 18, 40),
        to: DateTime.utc(2026, 3, 14, 20, 18, 40),
      ),
    );

    expect(series.seriesKey, 'climate_sensors.floor.temp');
    expect(series.points, isEmpty);
  });

  test('parses backend energy summary and preserves an unavailable bucket',
      () async {
    final source = TelemetryHistoryRemoteDataSourceImpl(
      mobileService: _FakeMobileV1Service(<String, dynamic>{
        'device_id': 'device-1',
        'serial': 'SN-1',
        'from': '2026-07-18T10:00:00Z',
        'to': '2026-07-19T10:00:00Z',
        'bucket': '1h',
        'timezone': 'Europe/Stockholm',
        'available_from': '2026-07-01T00:00:00Z',
        'coverage_ratio': 0.95,
        'total_kwh': 4.2,
        'average_bucket_kwh': 0.2,
        'peak_bucket_kwh': 0.8,
        'peak_bucket_from': '2026-07-19T08:00:00Z',
        'points': <Map<String, dynamic>>[
          {
            'from': '2026-07-19T08:00:00Z',
            'to': '2026-07-19T09:00:00Z',
            'energy_kwh': 0.8,
            'coverage_ratio': 1.0,
          },
          {
            'from': '2026-07-19T09:00:00Z',
            'to': '2026-07-19T10:00:00Z',
            'energy_kwh': null,
            'coverage_ratio': 0.5,
          },
        ],
      }),
    );

    final usage = await source.getEnergyUsage(
      serial: 'SN-1',
      query: TelemetryUsageQuery.bucketed(
        from: DateTime.utc(2026, 7, 18, 10),
        to: DateTime.utc(2026, 7, 19, 10),
        bucket: TelemetryUsageBucket.hour,
        timezone: 'Europe/Stockholm',
      ),
    );

    expect(usage.totalKwh, 4.2);
    expect(usage.coverageRatio, 0.95);
    expect(usage.points, hasLength(2));
    expect(usage.points.last.energyKwh, isNull);
    expect(usage.points.last.coverageRatio, 0.5);
  });

  test('parses backend duration-weighted heating usage', () async {
    final source = TelemetryHistoryRemoteDataSourceImpl(
      mobileService: _FakeMobileV1Service(<String, dynamic>{
        'device_id': 'device-1',
        'serial': 'SN-1',
        'from': '2026-07-18T10:00:00Z',
        'to': '2026-07-19T10:00:00Z',
        'bucket': '1h',
        'timezone': 'UTC',
        'available_from': '2026-07-18T00:00:00Z',
        'coverage_ratio': 1.0,
        'load_factor_percent': 35.0,
        'min_bucket_percent': 10.0,
        'max_bucket_percent': 80.0,
        'points': <Map<String, dynamic>>[
          {
            'from': '2026-07-19T09:00:00Z',
            'to': '2026-07-19T10:00:00Z',
            'load_factor_percent': 35.0,
            'coverage_ratio': 1.0,
          },
        ],
      }),
    );

    final usage = await source.getHeatingUsage(
      serial: 'SN-1',
      query: TelemetryUsageQuery.bucketed(
        from: DateTime.utc(2026, 7, 18, 10),
        to: DateTime.utc(2026, 7, 19, 10),
        bucket: TelemetryUsageBucket.hour,
        timezone: 'UTC',
      ),
    );

    expect(usage.loadFactorPercent, 35);
    expect(usage.minBucketPercent, 10);
    expect(usage.maxBucketPercent, 80);
    expect(usage.points.single.loadFactorPercent, 35);
  });
}
