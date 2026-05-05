import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/core/network/rest_response_error_mapper.dart';

class MobileV1ResponseMapper {
  const MobileV1ResponseMapper._();

  static List<Device> requireDeviceList(Response<dynamic> response) {
    final body = _decodeList(response.body);
    if (!response.isSuccessful || body == null) {
      throw RestResponseErrorMapper.toServerException(response);
    }

    return body
        .whereType<Map>()
        .map((item) => _deviceFromSummary(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Device requireDevice(Response<dynamic> response) {
    final body = requireJsonMap(response);
    return _deviceFromSummary(body);
  }

  static Map<String, dynamic> requireJsonMap(Response<dynamic> response) {
    final body = _decodeMap(response.body);
    if (!response.isSuccessful || body == null) {
      throw RestResponseErrorMapper.toServerException(response);
    }
    return body;
  }

  static List<Map<String, dynamic>> requireJsonList(
      Response<dynamic> response) {
    final body = _decodeList(response.body);
    if (!response.isSuccessful || body == null) {
      throw RestResponseErrorMapper.toServerException(response);
    }
    return body
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  static void ensureSuccess(Response<dynamic> response) {
    RestResponseErrorMapper.throwIfFailed(response);
  }

  static Device _deviceFromSummary(Map<String, dynamic> json) {
    return Device(
      id: _readString(json, 'device_id', 'deviceId'),
      sn: _readString(json, 'serial', 'serialNumber'),
      modelId: _readString(json, 'model_id', 'modelId'),
      modelName: _readString(json, 'model_name', 'modelName'),
      userData: DeviceUserData(
        alias: _readString(json, 'alias'),
        description: _readString(json, 'description'),
      ),
      connectionInfo: ConnectionInfo(
        online: _readBool(json, 'online'),
        timestamp: _parseTimestamp(
          _readRaw(json, 'last_seen_at', 'lastSeenAt'),
        ),
      ),
    );
  }

  static dynamic _readRaw(Map<String, dynamic> json, String key,
      [String? altKey]) {
    if (json.containsKey(key)) return json[key];
    if (altKey != null && json.containsKey(altKey)) return json[altKey];
    return null;
  }

  static String _readString(Map<String, dynamic> json, String key,
      [String? altKey]) {
    final raw = _readRaw(json, key, altKey);
    if (raw == null) return '';
    return raw.toString();
  }

  static bool _readBool(Map<String, dynamic> json, String key,
      [String? altKey]) {
    final raw = _readRaw(json, key, altKey);
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return false;
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    if (raw is num) return _epochToUtc(raw);

    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso.toUtc();

    final numeric = num.tryParse(text);
    if (numeric != null) return _epochToUtc(numeric);

    return null;
  }

  static DateTime _epochToUtc(num value) {
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

  static Map<String, dynamic>? _decodeMap(dynamic raw) {
    return RestResponseErrorMapper.decodeMap(raw);
  }

  static List<dynamic>? _decodeList(dynamic raw) {
    return RestResponseErrorMapper.decodeList(raw);
  }
}
