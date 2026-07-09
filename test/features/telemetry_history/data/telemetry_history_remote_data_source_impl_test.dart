import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source_impl.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';

void main() {
  test('parses telemetry aggregate sum values from mobile API response',
      () async {
    final service = _FakeMobileV1Service();
    final dataSource = TelemetryHistoryRemoteDataSourceImpl(
      mobileService: service,
    );
    final from = DateTime.utc(2026, 3, 13, 10);
    final to = DateTime.utc(2026, 3, 14, 10);

    final aggregate = await dataSource.getAggregate(
      serial: 'SN-1',
      query: TelemetryAggregateQuery(
        seriesKeys: const <String>['power_meter.energy_wh_delta'],
        from: from,
        to: to,
      ),
    );

    expect(service.lastSerial, 'SN-1');
    expect(service.lastSeriesKeys, 'power_meter.energy_wh_delta');
    expect(service.lastFrom, from.toIso8601String());
    expect(service.lastTo, to.toIso8601String());
    expect(service.lastResolution, 'auto');
    expect(aggregate.deviceId, 'device-1');
    expect(aggregate.serial, 'SN-1');
    expect(aggregate.resolution, '5m');
    expect(aggregate.series, hasLength(1));
    expect(aggregate.series.single.seriesKey, 'power_meter.energy_wh_delta');
    expect(aggregate.series.single.unit, 'Wh');
    expect(aggregate.series.single.samplesCount, 24);
    expect(aggregate.series.single.sumValue, 1000.0);
  });
}

class _FakeMobileV1Service extends MobileV1Service {
  String? lastSerial;
  String? lastSeriesKeys;
  String? lastFrom;
  String? lastTo;
  String? lastResolution;

  @override
  Future<Response<dynamic>> getMyDeviceTelemetryAggregate({
    required String serial,
    required String seriesKeys,
    required String from,
    required String to,
    String resolution = 'auto',
  }) async {
    lastSerial = serial;
    lastSeriesKeys = seriesKeys;
    lastFrom = from;
    lastTo = to;
    lastResolution = resolution;
    return Response<dynamic>(
      http.Response('', 200),
      <String, dynamic>{
        'device_id': 'device-1',
        'serial': 'SN-1',
        'from': from,
        'to': to,
        'resolution': '5m',
        'series': <Map<String, dynamic>>[
          <String, dynamic>{
            'series_key': 'power_meter.energy_wh_delta',
            'value_type': 'numeric',
            'unit': 'Wh',
            'samples_count': 24,
            'min_value': 420.0,
            'max_value': 580.0,
            'avg_value': 1000.0 / 24.0,
            'sum_value': 1000.0,
            'last_numeric_value': 580.0,
          },
        ],
      },
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
