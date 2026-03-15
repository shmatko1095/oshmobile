import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/common/entities/device/connection_info.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/common/entities/device/device_user_data.dart';
import 'package:oshmobile/core/error/exceptions.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

class MobileApiClient {
  const MobileApiClient({
    required ChopperClient client,
  }) : _client = client;

  final ChopperClient _client;

  Future<List<Device>> listMyDevices() async {
    final response = await _send('GET', '/me/devices');
    final body = _decodeList(response.body);
    if (!response.isSuccessful || body == null) {
      throw ServerException(_errorMessage(response));
    }

    return body
        .whereType<Map>()
        .map((item) => _deviceFromSummary(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<Device> getMyDevice({
    required String serial,
  }) async {
    final response = await _send('GET', '/devices/$serial');
    final body = _decodeMap(response.body);
    if (!response.isSuccessful || body == null) {
      throw ServerException(_errorMessage(response));
    }
    return _deviceFromSummary(body);
  }

  Future<void> claimMyDevice({
    required String serial,
    required String secureCode,
  }) async {
    final response = await _send('POST', '/devices/$serial/claim', body: {
      'sc': secureCode,
    });
    if (!response.isSuccessful) {
      throw ServerException(_errorMessage(response));
    }
  }

  Future<void> unassignMyDevice({
    required String serial,
  }) async {
    final response = await _send('DELETE', '/devices/$serial');
    if (!response.isSuccessful) {
      throw ServerException(_errorMessage(response));
    }
  }

  Future<void> updateMyDeviceUserData({
    required String serial,
    required String alias,
    required String description,
  }) async {
    final response = await _send('PUT', '/devices/$serial/userdata', body: {
      'alias': alias,
      'description': description,
    });
    if (!response.isSuccessful) {
      throw ServerException(_errorMessage(response));
    }
  }

  Future<Map<String, dynamic>> getMyDeviceTelemetryHistoryRaw({
    required String serial,
    required String seriesKey,
    required DateTime from,
    required DateTime to,
    String resolution = 'auto',
    String apiVersion = 'v1',
  }) async {
    final response = await _sendVersioned(
      'GET',
      '/devices/$serial/telemetry/history',
      apiVersion: apiVersion,
      queryParameters: {
        'series_key': seriesKey,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'resolution': resolution,
      },
    );

    final body = _decodeMap(response.body);
    if (!response.isSuccessful || body == null) {
      throw ServerException(_errorMessage(response));
    }
    return body;
  }

  Future<Response<dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _sendVersioned(
      method,
      path,
      apiVersion: 'v1',
      body: body,
    );
  }

  Future<Response<dynamic>> _sendVersioned(
    String method,
    String path, {
    required String apiVersion,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final root = _apiRootForVersion(apiVersion);
    final baseUri = Uri.parse('$root/mobile$path');
    final uri = (queryParameters == null || queryParameters.isEmpty)
        ? baseUri
        : baseUri.replace(queryParameters: {
            ...baseUri.queryParameters,
            ...queryParameters,
          });

    final request = Request(method, uri, _client.baseUrl, body: body);
    return _client.send<dynamic, dynamic>(request);
  }

  String _apiRootForVersion(String apiVersion) {
    final normalized = apiVersion.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'v1') {
      return AppSecrets.oshApiEndpoint;
    }

    final uri = Uri.parse(AppSecrets.oshApiEndpoint);
    final segments = List<String>.from(uri.pathSegments);
    if (segments.isNotEmpty && segments.last.toLowerCase().startsWith('v')) {
      segments[segments.length - 1] = normalized;
    } else {
      segments.add(normalized);
    }

    return uri.replace(pathSegments: segments).toString();
  }

  Device _deviceFromSummary(Map<String, dynamic> json) {
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

  dynamic _readRaw(Map<String, dynamic> json, String key, [String? altKey]) {
    if (json.containsKey(key)) return json[key];
    if (altKey != null && json.containsKey(altKey)) return json[altKey];
    return null;
  }

  String _readString(Map<String, dynamic> json, String key, [String? altKey]) {
    final raw = _readRaw(json, key, altKey);
    if (raw == null) return '';
    return raw.toString();
  }

  bool _readBool(Map<String, dynamic> json, String key, [String? altKey]) {
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

  DateTime? _parseTimestamp(dynamic raw) {
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

  Map<String, dynamic>? _decodeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    return null;
  }

  List<dynamic>? _decodeList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    }
    return null;
  }

  String _errorMessage(Response<dynamic> response) {
    final map = _decodeMap(response.body) ?? _decodeMap(response.error);
    if (map != null) {
      final nested = map['grpc_response'];
      if (nested is Map) {
        final nestedMessage = nested['message']?.toString();
        if (nestedMessage != null && nestedMessage.isNotEmpty) {
          return nestedMessage;
        }
      }
      for (final key in ['message', 'detail', 'error']) {
        final value = map[key]?.toString();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }
    return 'HTTP ${response.statusCode}';
  }
}
