import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source_impl.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_kind.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_quality.dart';

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

  test('parses typed atomic setpoint states and their invariants', () async {
    final from = DateTime.utc(2026, 3, 14, 10);
    final service = _FakeMobileV1Service()
      ..typedSetpointResponse = _response(
        200,
        <String, dynamic>{
          'device_id': 'device-1',
          'serial': 'SN-1',
          'resolution': '5m',
          'from': from.toIso8601String(),
          'to': from.add(const Duration(hours: 1)).toIso8601String(),
          'points': <Map<String, dynamic>>[
            _typedPoint(from, kind: 'temperature', temp: 21.5),
            _typedPoint(from.add(const Duration(minutes: 5)), kind: 'on'),
            _typedPoint(from.add(const Duration(minutes: 10)), kind: 'off'),
            _typedPoint(
              from.add(const Duration(minutes: 15)),
              kind: 'inactive',
            ),
          ],
        },
      );
    final dataSource = TelemetryHistoryRemoteDataSourceImpl(
      mobileService: service,
    );

    final history = await dataSource.getSetpointHistory(
      serial: 'SN-1',
      query: TelemetryHistoryQuery(
        seriesKey: 'target',
        from: from,
        to: from.add(const Duration(hours: 1)),
      ),
    );

    expect(
      history.points.map((point) => point.state.kind),
      <TelemetrySetpointKind>[
        TelemetrySetpointKind.temperature,
        TelemetrySetpointKind.on,
        TelemetrySetpointKind.off,
        TelemetrySetpointKind.inactive,
      ],
    );
    expect(history.points.first.state.temperature, 21.5);
    expect(
      history.points.skip(1).every((point) => point.state.temperature == null),
      isTrue,
    );
    expect(
      history.points.every(
        (point) => point.quality == TelemetrySetpointQuality.exact,
      ),
      isTrue,
    );
    expect(service.legacyHistoryCalls, 0);
  });

  test('falls back on 404 and resolves only unambiguous exact buckets',
      () async {
    final from = DateTime.utc(2026, 3, 14, 10);
    final service = _FakeMobileV1Service()
      ..typedSetpointResponse = _response(404, <String, dynamic>{})
      ..legacyHistoryResponse = _response(
        200,
        <String, dynamic>{
          'device_id': 'device-1',
          'serial': 'SN-1',
          'resolution': '5m',
          'from': from.toIso8601String(),
          'to': from.add(const Duration(hours: 1)).toIso8601String(),
          'series': <Map<String, dynamic>>[
            _legacySeries('target_temp', <Map<String, dynamic>>[
              _numericPoint(from, 21),
              _numericPoint(from.add(const Duration(minutes: 15)), 22),
            ]),
            _legacySeries('setpoint_on', <Map<String, dynamic>>[
              _boolPoint(from, false),
              _boolPoint(from.add(const Duration(minutes: 5)), true),
              _boolPoint(from.add(const Duration(minutes: 15)), true),
            ]),
            _legacySeries('setpoint_off', <Map<String, dynamic>>[
              _boolPoint(from, false),
              _boolPoint(from.add(const Duration(minutes: 5)), false),
              _boolPoint(from.add(const Duration(minutes: 10)), true),
              _boolPoint(from.add(const Duration(minutes: 15)), false),
            ]),
          ],
        },
      );
    final dataSource = TelemetryHistoryRemoteDataSourceImpl(
      mobileService: service,
    );

    final history = await dataSource.getSetpointHistory(
      serial: 'SN-1',
      query: TelemetryHistoryQuery(
        seriesKey: 'target',
        from: from,
        to: from.add(const Duration(hours: 1)),
      ),
    );

    expect(service.legacyHistoryCalls, 1);
    expect(
      history.points.map((point) => point.bucketStart),
      <DateTime>[from, from.add(const Duration(minutes: 5))],
    );
    expect(
      history.points.map((point) => point.state.kind),
      <TelemetrySetpointKind>[
        TelemetrySetpointKind.temperature,
        TelemetrySetpointKind.on,
      ],
    );
    expect(
      history.points.every(
        (point) => point.quality == TelemetrySetpointQuality.legacyDerived,
      ),
      isTrue,
    );
  });

  test('does not hide malformed typed responses behind legacy fallback',
      () async {
    final from = DateTime.utc(2026, 3, 14, 10);
    final invalidPoints = <Map<String, dynamic>>[
      _typedPoint(from, kind: 'on', temp: 21),
      _typedPoint(from, kind: 'temperature'),
      _typedPoint(from, kind: 'future_kind'),
      <String, dynamic>{
        ..._typedPoint(from, kind: 'off'),
        'quality': 'unknown',
      },
    ];

    for (final invalidPoint in invalidPoints) {
      final service = _FakeMobileV1Service()
        ..typedSetpointResponse = _response(
          200,
          <String, dynamic>{
            'device_id': 'device-1',
            'serial': 'SN-1',
            'resolution': '5m',
            'from': from.toIso8601String(),
            'to': from.add(const Duration(hours: 1)).toIso8601String(),
            'points': <Map<String, dynamic>>[invalidPoint],
          },
        );
      final dataSource = TelemetryHistoryRemoteDataSourceImpl(
        mobileService: service,
      );

      await expectLater(
        dataSource.getSetpointHistory(
          serial: 'SN-1',
          query: TelemetryHistoryQuery(
            seriesKey: 'target',
            from: from,
            to: from.add(const Duration(hours: 1)),
          ),
        ),
        throwsFormatException,
      );
      expect(service.legacyHistoryCalls, 0);
    }
  });

  test('does not fall back for typed endpoint server failures', () async {
    final from = DateTime.utc(2026, 3, 14, 10);
    final service = _FakeMobileV1Service()
      ..typedSetpointResponse = _response(500, <String, dynamic>{});
    final dataSource = TelemetryHistoryRemoteDataSourceImpl(
      mobileService: service,
    );

    await expectLater(
      dataSource.getSetpointHistory(
        serial: 'SN-1',
        query: TelemetryHistoryQuery(
          seriesKey: 'target',
          from: from,
          to: from.add(const Duration(hours: 1)),
        ),
      ),
      throwsA(anything),
    );
    expect(service.legacyHistoryCalls, 0);
  });
}

Response<dynamic> _response(int statusCode, dynamic body) {
  return Response<dynamic>(http.Response('', statusCode), body);
}

Map<String, dynamic> _typedPoint(
  DateTime timestamp, {
  required String kind,
  double? temp,
}) {
  return <String, dynamic>{
    'bucket_start': timestamp.toIso8601String(),
    'observed_at': timestamp.add(const Duration(seconds: 30)).toIso8601String(),
    'kind': kind,
    if (temp != null) 'temp': temp,
    'quality': 'exact',
  };
}

Map<String, dynamic> _legacySeries(
  String key,
  List<Map<String, dynamic>> points,
) {
  return <String, dynamic>{'series_key': key, 'points': points};
}

Map<String, dynamic> _numericPoint(DateTime timestamp, double value) {
  return <String, dynamic>{
    'bucket_start': timestamp.toIso8601String(),
    'last_numeric_value': value,
    'samples_count': 1,
  };
}

Map<String, dynamic> _boolPoint(DateTime timestamp, bool value) {
  return <String, dynamic>{
    'bucket_start': timestamp.toIso8601String(),
    'last_bool_value': value,
    'samples_count': 1,
  };
}

class _FakeMobileV1Service extends MobileV1Service {
  String? lastSerial;
  String? lastSeriesKeys;
  String? lastFrom;
  String? lastTo;
  String? lastResolution;
  Response<dynamic>? typedSetpointResponse;
  Response<dynamic>? legacyHistoryResponse;
  int legacyHistoryCalls = 0;

  @override
  Future<Response<dynamic>> getMyDeviceThermostatSetpointHistory({
    required String serial,
    required String from,
    required String to,
    String resolution = 'auto',
  }) async {
    return typedSetpointResponse ?? _response(501, <String, dynamic>{});
  }

  @override
  Future<Response<dynamic>> getMyDeviceTelemetryHistory({
    required String serial,
    required String seriesKeys,
    required String from,
    required String to,
    String resolution = 'auto',
  }) async {
    legacyHistoryCalls++;
    return legacyHistoryResponse ?? _response(500, <String, dynamic>{});
  }

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
