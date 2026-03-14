import 'package:oshmobile/core/network/mobile/mobile_api_client.dart';
import 'package:oshmobile/features/telemetry_history/data/datasources/telemetry_history_remote_data_source.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_api_version.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_point.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_query.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';

class TelemetryHistoryRemoteDataSourceImpl
    implements TelemetryHistoryRemoteDataSource {
  const TelemetryHistoryRemoteDataSourceImpl({
    required MobileApiClient mobileApiClient,
  }) : _mobileApiClient = mobileApiClient;

  final MobileApiClient _mobileApiClient;

  @override
  Future<TelemetryHistorySeries> getSeries({
    required String serial,
    required TelemetryHistoryQuery query,
  }) async {
    final raw = await _mobileApiClient.getMyDeviceTelemetryHistoryRaw(
      serial: serial,
      seriesKey: query.seriesKey,
      from: query.from,
      to: query.to,
      resolution: query.preferredResolution,
      apiVersion: _apiVersionLabel(query.apiVersion),
    );

    return _parse(raw, fallbackSerial: serial, fallbackQuery: query);
  }

  String _apiVersionLabel(TelemetryHistoryApiVersion version) {
    return switch (version) {
      TelemetryHistoryApiVersion.v1 => 'v1',
      TelemetryHistoryApiVersion.v2 => 'v2',
    };
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
    final seriesKey = _readString(payload, 'series_key') ??
        _readString(payload, 'seriesKey') ??
        fallbackQuery.seriesKey;
    final resolution = (_readString(payload, 'resolution') ?? 'auto').trim();

    final from = _readDate(payload, 'from') ?? fallbackQuery.from.toUtc();
    final to = _readDate(payload, 'to') ?? fallbackQuery.to.toUtc();

    final pointsRaw = _readList(payload, 'points');
    final points = pointsRaw
        .whereType<Map>()
        .map((item) => _parsePoint(item.cast<String, dynamic>()))
        .whereType<TelemetryHistoryPoint>()
        .toList(growable: false)
      ..sort((a, b) => a.bucketStart.compareTo(b.bucketStart));

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
      lastNumericValue: _readDouble(raw, 'last_numeric_value') ??
          _readDouble(raw, 'lastNumericValue'),
      lastBoolValue:
          _readBool(raw, 'last_bool_value') ?? _readBool(raw, 'lastBoolValue'),
      trueRatio:
          _readDouble(raw, 'true_ratio') ?? _readDouble(raw, 'trueRatio'),
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
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _readDouble(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
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
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
