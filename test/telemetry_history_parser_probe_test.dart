import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/claim_my_device_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/requests/update_my_device_user_data_request.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source_impl.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';

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
    expect(series.points.first.bucketStart, DateTime.utc(2026, 3, 14, 19, 30));
  });
}
