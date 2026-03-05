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

  Future<Response<dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AppSecrets.oshApiEndpoint}/mobile$path');
    final request = Request(method, uri, _client.baseUrl, body: body);
    return _client.send<dynamic, dynamic>(request);
  }

  Device _deviceFromSummary(Map<String, dynamic> json) {
    return Device(
      id: json['device_id']?.toString() ?? '',
      sn: json['serial']?.toString() ?? '',
      modelId: json['model_id']?.toString() ?? '',
      userData: DeviceUserData(
        alias: json['alias']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
      ),
      connectionInfo: ConnectionInfo(
        online: json['online'] == true,
        timestamp: _parseTimestamp(json['last_seen_at']),
      ),
    );
  }

  DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toUtc();
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
