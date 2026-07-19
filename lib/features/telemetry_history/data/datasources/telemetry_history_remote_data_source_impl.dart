import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_response_mapper.dart';
import 'package:oshmobile/core/network/chopper_client/osh_api/v1/mobile/mobile_v1_service.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_aggregate_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_history.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_quality.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_setpoint_state.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/energy_usage_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/heating_usage_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_usage_query.dart';

class TelemetryHistoryRemoteDataSourceImpl
    implements TelemetryHistoryRemoteDataSource {
  const TelemetryHistoryRemoteDataSourceImpl({
    required MobileV1Service mobileService,
  }) : _mobileService = mobileService;

  final MobileV1Service _mobileService;

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String serial,
    required TelemetryHistoryQuery query,
  }) async {
    final response = await _mobileService.getMyDeviceTelemetryHistory(
      serial: serial,
      seriesKeys: query.seriesKey,
      from: query.from.toUtc().toIso8601String(),
      to: query.to.toUtc().toIso8601String(),
      resolution: query.preferredResolution,
    );
    final raw = MobileV1ResponseMapper.requireJsonMap(response);

    return _parse(raw, fallbackSerial: serial, fallbackQuery: query);
  }

  @override
  Future<TelemetryAggregate> getAggregate({
    required String serial,
    required TelemetryAggregateQuery query,
  }) async {
    final response = await _mobileService.getMyDeviceTelemetryAggregate(
      serial: serial,
      seriesKeys: query.seriesKeys.join(','),
      from: query.from.toUtc().toIso8601String(),
      to: query.to.toUtc().toIso8601String(),
      resolution: query.preferredResolution,
    );
    final raw = MobileV1ResponseMapper.requireJsonMap(response);

    return _parseAggregate(
      raw,
      fallbackSerial: serial,
      fallbackQuery: query,
    );
  }

  @override
  Future<EnergyUsage> getEnergyUsage({
    required String serial,
    required TelemetryUsageQuery query,
  }) async {
    final response = await _mobileService.getMyDeviceEnergyUsage(
      serial: serial,
      from: query.from.toUtc().toIso8601String(),
      to: query.to.toUtc().toIso8601String(),
      bucket: query.bucket?.wireValue,
      timezone: query.timezone,
    );
    final payload =
        _unwrapPayload(MobileV1ResponseMapper.requireJsonMap(response));
    final coverage = _requiredCoverage(payload);
    final points = _readList(payload, 'points').map((rawPoint) {
      if (rawPoint is! Map) {
        throw const FormatException('Energy usage point must be an object.');
      }
      final point = rawPoint.cast<String, dynamic>();
      final from = _readDate(point, 'from');
      final to = _readDate(point, 'to');
      final pointCoverage = _requiredCoverage(point);
      if (from == null || to == null || !from.isBefore(to)) {
        throw const FormatException(
            'Energy usage point has an invalid interval.');
      }
      return EnergyUsagePoint(
        from: from,
        to: to,
        energyKwh: _finiteNullableDouble(point, 'energy_kwh'),
        coverageRatio: pointCoverage,
      );
    }).toList(growable: false)
      ..sort((a, b) => a.from.compareTo(b.from));
    return EnergyUsage(
      deviceId: _readString(payload, 'device_id') ?? '',
      serial: _readString(payload, 'serial') ?? serial,
      from: _requiredDate(payload, 'from'),
      to: _requiredDate(payload, 'to'),
      bucket: _readString(payload, 'bucket') ?? '',
      timezone: _readString(payload, 'timezone') ?? query.timezone ?? 'UTC',
      availableFrom: _readDate(payload, 'available_from'),
      coverageRatio: coverage,
      totalKwh: _finiteNullableDouble(payload, 'total_kwh'),
      averageBucketKwh: _finiteNullableDouble(payload, 'average_bucket_kwh'),
      peakBucketKwh: _finiteNullableDouble(payload, 'peak_bucket_kwh'),
      peakBucketFrom: _readDate(payload, 'peak_bucket_from'),
      points: points,
    );
  }

  @override
  Future<HeatingUsage> getHeatingUsage({
    required String serial,
    required TelemetryUsageQuery query,
  }) async {
    final response = await _mobileService.getMyDeviceHeatingUsage(
      serial: serial,
      from: query.from.toUtc().toIso8601String(),
      to: query.to.toUtc().toIso8601String(),
      bucket: query.bucket?.wireValue,
      timezone: query.timezone,
    );
    final payload =
        _unwrapPayload(MobileV1ResponseMapper.requireJsonMap(response));
    final coverage = _requiredCoverage(payload);
    final points = _readList(payload, 'points').map((rawPoint) {
      if (rawPoint is! Map) {
        throw const FormatException('Heating usage point must be an object.');
      }
      final point = rawPoint.cast<String, dynamic>();
      final from = _readDate(point, 'from');
      final to = _readDate(point, 'to');
      final pointCoverage = _requiredCoverage(point);
      if (from == null || to == null || !from.isBefore(to)) {
        throw const FormatException(
            'Heating usage point has an invalid interval.');
      }
      return HeatingUsagePoint(
        from: from,
        to: to,
        loadFactorPercent: _finiteNullableDouble(point, 'load_factor_percent'),
        coverageRatio: pointCoverage,
      );
    }).toList(growable: false)
      ..sort((a, b) => a.from.compareTo(b.from));
    return HeatingUsage(
      deviceId: _readString(payload, 'device_id') ?? '',
      serial: _readString(payload, 'serial') ?? serial,
      from: _requiredDate(payload, 'from'),
      to: _requiredDate(payload, 'to'),
      bucket: _readString(payload, 'bucket') ?? '',
      timezone: _readString(payload, 'timezone') ?? query.timezone ?? 'UTC',
      availableFrom: _readDate(payload, 'available_from'),
      coverageRatio: coverage,
      loadFactorPercent: _finiteNullableDouble(payload, 'load_factor_percent'),
      minBucketPercent: _finiteNullableDouble(payload, 'min_bucket_percent'),
      maxBucketPercent: _finiteNullableDouble(payload, 'max_bucket_percent'),
      points: points,
    );
  }

  @override
  Future<TelemetrySetpointHistory> getSetpointHistory({
    required String serial,
    required TelemetryHistoryQuery query,
  }) async {
    final typedResponse =
        await _mobileService.getMyDeviceThermostatSetpointHistory(
      serial: serial,
      from: query.from.toUtc().toIso8601String(),
      to: query.to.toUtc().toIso8601String(),
      resolution: query.preferredResolution,
    );
    if (typedResponse.statusCode == 404 || typedResponse.statusCode == 501) {
      return _getLegacySetpointHistory(serial: serial, query: query);
    }
    final raw = MobileV1ResponseMapper.requireJsonMap(typedResponse);
    return _parseSetpointHistory(raw);
  }

  Future<TelemetrySetpointHistory> _getLegacySetpointHistory({
    required String serial,
    required TelemetryHistoryQuery query,
  }) async {
    final response = await _mobileService.getMyDeviceTelemetryHistory(
      serial: serial,
      seriesKeys: 'target_temp,setpoint_on,setpoint_off',
      from: query.from.toUtc().toIso8601String(),
      to: query.to.toUtc().toIso8601String(),
      resolution: query.preferredResolution,
    );
    final raw = MobileV1ResponseMapper.requireJsonMap(response);
    return _parseLegacySetpointHistory(
      raw,
      fallbackSerial: serial,
      fallbackQuery: query,
    );
  }

  TelemetrySetpointHistory _parseSetpointHistory(Map<String, dynamic> raw) {
    final payload = _unwrapPayload(raw);
    final deviceId =
        _readString(payload, 'device_id') ?? _readString(payload, 'deviceId');
    final serial = _readString(payload, 'serial');
    final resolution = _readString(payload, 'resolution')?.trim();
    final from = _readDate(payload, 'from');
    final to = _readDate(payload, 'to');
    final rawPoints = payload['points'];
    if (deviceId == null ||
        deviceId.trim().isEmpty ||
        serial == null ||
        serial.trim().isEmpty ||
        resolution == null ||
        !const <String>{'5m', '30m', '24h'}.contains(resolution) ||
        from == null ||
        to == null ||
        !from.isBefore(to) ||
        rawPoints is! List) {
      throw const FormatException('Invalid typed setpoint history payload.');
    }
    final points = rawPoints.map((item) {
      if (item is! Map) {
        throw const FormatException(
            'Setpoint history point must be an object.');
      }
      return _parseSetpointPoint(item.cast<String, dynamic>());
    }).toList(growable: false)
      ..sort((a, b) => a.bucketStart.compareTo(b.bucketStart));
    return TelemetrySetpointHistory(
      deviceId: deviceId,
      serial: serial,
      resolution: resolution,
      from: from,
      to: to,
      points: points,
    );
  }

  TelemetrySetpointPoint _parseSetpointPoint(Map<String, dynamic> raw) {
    final bucketStart =
        _readDate(raw, 'bucket_start') ?? _readDate(raw, 'bucketStart');
    final observedAt =
        _readDate(raw, 'observed_at') ?? _readDate(raw, 'observedAt');
    if (bucketStart == null || observedAt == null) {
      throw const FormatException(
        'Setpoint history point requires bucket_start and observed_at.',
      );
    }
    final kind = (_readString(raw, 'kind') ?? '').trim().toLowerCase();
    final temp = _readDouble(raw, 'temp');
    final state = switch (kind) {
      'inactive' when temp == null => const TelemetrySetpointState.inactive(),
      'temperature' when temp != null && temp.isFinite =>
        TelemetrySetpointState.temperature(temp),
      'on' when temp == null => const TelemetrySetpointState.on(),
      'off' when temp == null => const TelemetrySetpointState.off(),
      _ => throw FormatException('Invalid setpoint history state: $kind.'),
    };
    final quality =
        switch ((_readString(raw, 'quality') ?? '').trim().toLowerCase()) {
      'exact' => TelemetrySetpointQuality.exact,
      'legacy_derived' => TelemetrySetpointQuality.legacyDerived,
      _ => throw const FormatException('Invalid setpoint history quality.'),
    };
    return TelemetrySetpointPoint(
      bucketStart: bucketStart,
      observedAt: observedAt,
      state: state,
      quality: quality,
    );
  }

  TelemetrySetpointHistory _parseLegacySetpointHistory(
    Map<String, dynamic> raw, {
    required String fallbackSerial,
    required TelemetryHistoryQuery fallbackQuery,
  }) {
    final payload = _unwrapPayload(raw);
    final series = _readList(payload, 'series')
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
    final byKey = <String, Map<DateTime, TelemetryHistoryPoint>>{};
    for (final item in series) {
      final key = _readString(item, 'series_key') ??
          _readString(item, 'seriesKey') ??
          '';
      byKey[key] = <DateTime, TelemetryHistoryPoint>{
        for (final point in _parsePoints(_readList(item, 'points')))
          point.bucketStart: point,
      };
    }

    final timestamps = <DateTime>{
      for (final points in byKey.values) ...points.keys,
    }.toList(growable: false)
      ..sort();
    final points = <TelemetrySetpointPoint>[];
    for (final timestamp in timestamps) {
      final target = byKey['target_temp']?[timestamp]?.lastNumericValue;
      final on = byKey['setpoint_on']?[timestamp]?.lastBoolValue;
      final off = byKey['setpoint_off']?[timestamp]?.lastBoolValue;
      final state = _deriveLegacySetpoint(target: target, on: on, off: off);
      if (state == null) continue;
      points.add(
        TelemetrySetpointPoint(
          bucketStart: timestamp,
          observedAt: timestamp,
          state: state,
          quality: TelemetrySetpointQuality.legacyDerived,
        ),
      );
    }
    return TelemetrySetpointHistory(
      deviceId: _readString(payload, 'device_id') ??
          _readString(payload, 'deviceId') ??
          '',
      serial: _readString(payload, 'serial') ?? fallbackSerial,
      resolution: (_readString(payload, 'resolution') ?? 'auto').trim(),
      from: _readDate(payload, 'from') ?? fallbackQuery.from.toUtc(),
      to: _readDate(payload, 'to') ?? fallbackQuery.to.toUtc(),
      points: points,
    );
  }

  TelemetrySetpointState? _deriveLegacySetpoint({
    required double? target,
    required bool? on,
    required bool? off,
  }) {
    if ((on == null) != (off == null)) return null;
    if (on == null) {
      return target == null ? null : TelemetrySetpointState.temperature(target);
    }
    if (on && off!) return null;
    if (on || off!) {
      if (target != null) return null;
      return on
          ? const TelemetrySetpointState.on()
          : const TelemetrySetpointState.off();
    }
    return target == null ? null : TelemetrySetpointState.temperature(target);
  }

  TelemetryHistorySeries _parse(
    Map<String, dynamic> raw, {
    required String fallbackSerial,
    required TelemetryHistoryQuery fallbackQuery,
  }) {
    final payload = _unwrapPayload(raw);

    final deviceId = _readString(payload, 'device_id') ??
        _readString(payload, 'deviceId') ??
        '';
    final serial = _readString(payload, 'serial') ?? fallbackSerial;
    final resolution = (_readString(payload, 'resolution') ?? 'auto').trim();
    final from = _readDate(payload, 'from') ?? fallbackQuery.from.toUtc();
    final to = _readDate(payload, 'to') ?? fallbackQuery.to.toUtc();

    final multiSeries = _readList(payload, 'series')
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
    if (multiSeries.isNotEmpty) {
      final selected = _findSeriesPayload(multiSeries, fallbackQuery.seriesKey);
      if (selected == null) {
        return _emptySeries(
          deviceId: deviceId,
          serial: serial,
          seriesKey: fallbackQuery.seriesKey,
          resolution: resolution,
          from: from,
          to: to,
        );
      }
      final seriesKey = _readString(selected, 'series_key') ??
          _readString(selected, 'seriesKey') ??
          fallbackQuery.seriesKey;
      final points = _parsePoints(_readList(selected, 'points'));
      return TelemetryHistorySeries(
        deviceId: deviceId,
        serial: serial,
        seriesKey: seriesKey,
        resolution: resolution,
        from: from,
        to: to,
        points: points,
      );
    }

    final seriesKey = _readString(payload, 'series_key') ??
        _readString(payload, 'seriesKey') ??
        fallbackQuery.seriesKey;
    final points = _parsePoints(_readList(payload, 'points'));
    return TelemetryHistorySeries(
      deviceId: deviceId,
      serial: serial,
      seriesKey: seriesKey,
      resolution: resolution,
      from: from,
      to: to,
      points: points,
    );
  }

  TelemetryAggregate _parseAggregate(
    Map<String, dynamic> raw, {
    required String fallbackSerial,
    required TelemetryAggregateQuery fallbackQuery,
  }) {
    final payload = _unwrapPayload(raw);

    final deviceId = _readString(payload, 'device_id') ??
        _readString(payload, 'deviceId') ??
        '';
    final serial = _readString(payload, 'serial') ?? fallbackSerial;
    final resolution = (_readString(payload, 'resolution') ?? 'auto').trim();
    final from = _readDate(payload, 'from') ?? fallbackQuery.from.toUtc();
    final to = _readDate(payload, 'to') ?? fallbackQuery.to.toUtc();
    final series = _readList(payload, 'series')
        .whereType<Map>()
        .map((item) => _parseAggregateSeries(item.cast<String, dynamic>()))
        .toList(growable: false);

    return TelemetryAggregate(
      deviceId: deviceId,
      serial: serial,
      resolution: resolution,
      from: from,
      to: to,
      series: series,
    );
  }

  TelemetryAggregateSeries _parseAggregateSeries(Map<String, dynamic> raw) {
    return TelemetryAggregateSeries(
      seriesKey:
          _readString(raw, 'series_key') ?? _readString(raw, 'seriesKey') ?? '',
      valueType:
          _readString(raw, 'value_type') ?? _readString(raw, 'valueType') ?? '',
      unit: _readString(raw, 'unit') ?? '',
      samplesCount:
          _readInt(raw, 'samples_count') ?? _readInt(raw, 'samplesCount') ?? 0,
      minValue: _readDouble(raw, 'min_value') ?? _readDouble(raw, 'minValue'),
      maxValue: _readDouble(raw, 'max_value') ?? _readDouble(raw, 'maxValue'),
      avgValue: _readDouble(raw, 'avg_value') ?? _readDouble(raw, 'avgValue'),
      sumValue: _readDouble(raw, 'sum_value') ?? _readDouble(raw, 'sumValue'),
      lastNumericValue: _readDouble(raw, 'last_numeric_value') ??
          _readDouble(raw, 'lastNumericValue'),
      trueCount: _readInt(raw, 'true_count') ?? _readInt(raw, 'trueCount') ?? 0,
      trueRatio:
          _readDouble(raw, 'true_ratio') ?? _readDouble(raw, 'trueRatio'),
      lastBoolValue:
          _readBool(raw, 'last_bool_value') ?? _readBool(raw, 'lastBoolValue'),
    );
  }

  Map<String, dynamic>? _findSeriesPayload(
    List<Map<String, dynamic>> series,
    String requestedSeriesKey,
  ) {
    for (final item in series) {
      final key = _readString(item, 'series_key') ??
          _readString(item, 'seriesKey') ??
          '';
      if (key == requestedSeriesKey) {
        return item;
      }
    }
    return null;
  }

  TelemetryHistorySeries _emptySeries({
    required String deviceId,
    required String serial,
    required String seriesKey,
    required String resolution,
    required DateTime from,
    required DateTime to,
  }) {
    return TelemetryHistorySeries(
      deviceId: deviceId,
      serial: serial,
      seriesKey: seriesKey,
      resolution: resolution,
      from: from,
      to: to,
      points: const <TelemetryHistoryPoint>[],
    );
  }

  List<TelemetryHistoryPoint> _parsePoints(List<dynamic> rawPoints) {
    return rawPoints
        .whereType<Map>()
        .map((item) => _parsePoint(item.cast<String, dynamic>()))
        .whereType<TelemetryHistoryPoint>()
        .toList(growable: false)
      ..sort((a, b) => a.bucketStart.compareTo(b.bucketStart));
  }

  Map<String, dynamic> _unwrapPayload(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return raw;
  }

  TelemetryHistoryPoint? _parsePoint(Map<String, dynamic> raw) {
    final bucketStart =
        _readDate(raw, 'bucket_start') ?? _readDate(raw, 'bucketStart');
    if (bucketStart == null) {
      return null;
    }

    final samplesCount =
        _readInt(raw, 'samples_count') ?? _readInt(raw, 'samplesCount') ?? 0;

    return TelemetryHistoryPoint(
      bucketStart: bucketStart,
      samplesCount: samplesCount,
      minValue: _readDouble(raw, 'min_value') ?? _readDouble(raw, 'minValue'),
      maxValue: _readDouble(raw, 'max_value') ?? _readDouble(raw, 'maxValue'),
      avgValue: _readDouble(raw, 'avg_value') ?? _readDouble(raw, 'avgValue'),
      sumValue: _readDouble(raw, 'sum_value') ?? _readDouble(raw, 'sumValue'),
      lastNumericValue: _readDouble(raw, 'last_numeric_value') ??
          _readDouble(raw, 'lastNumericValue'),
      lastBoolValue:
          _readBool(raw, 'last_bool_value') ?? _readBool(raw, 'lastBoolValue'),
      trueRatio:
          _readDouble(raw, 'true_ratio') ?? _readDouble(raw, 'trueRatio'),
      referenceSensorId: _readString(raw, 'reference_sensor_id') ??
          _readString(raw, 'referenceSensorId'),
    );
  }

  String? _readString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  List<dynamic> _readList(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is List) return value;
    return const <dynamic>[];
  }

  int? _readInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      return int.tryParse(text) ?? num.tryParse(text)?.toInt();
    }
    return null;
  }

  double? _readDouble(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      return double.tryParse(text);
    }
    return null;
  }

  bool? _readBool(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }

  DateTime? _readDate(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    if (value is num) return _epochToUtc(value);

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final parsedIso = DateTime.tryParse(text);
    if (parsedIso != null) {
      return parsedIso.toUtc();
    }

    final parsedNum = num.tryParse(text);
    if (parsedNum != null) {
      return _epochToUtc(parsedNum);
    }
    return null;
  }

  DateTime _requiredDate(Map<String, dynamic> map, String key) {
    final value = _readDate(map, key);
    if (value == null) {
      throw FormatException('Usage payload requires $key.');
    }
    return value;
  }

  double _requiredCoverage(Map<String, dynamic> map) {
    final value = _finiteNullableDouble(map, 'coverage_ratio');
    if (value == null || value < 0 || value > 1) {
      throw const FormatException(
          'Usage coverage_ratio must be between 0 and 1.');
    }
    return value;
  }

  double? _finiteNullableDouble(Map<String, dynamic> map, String key) {
    final value = _readDouble(map, key);
    if (value == null) return null;
    if (!value.isFinite) {
      throw FormatException('Usage value $key must be finite or null.');
    }
    return value;
  }

  DateTime _epochToUtc(num value) {
    final abs = value.abs();
    if (abs >= 100000000000000) {
      return DateTime.fromMicrosecondsSinceEpoch(value.round(), isUtc: true);
    }
    if (abs >= 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value.round(), isUtc: true);
    }
    final micros = (value * 1000000).round();
    return DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
  }
}
