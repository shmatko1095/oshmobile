import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/configuration/configuration_bundle_repository.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

class ConfigurationBundleRepositoryImpl
    implements ConfigurationBundleRepository {
  const ConfigurationBundleRepositoryImpl({
    required ChopperClient client,
  }) : _client = client;

  final ChopperClient _client;

  @override
  Future<DeviceConfigurationBundle> fetchBundle({
    required String serial,
  }) async {
    final uri = Uri.parse(
      '${AppSecrets.oshApiEndpoint}/mobile/devices/$serial/configuration',
    );

    final request = Request('GET', uri, _client.baseUrl);
    final response = await _client.send<dynamic, dynamic>(request);
    final body = _decodeBody(response.body);
    if (!response.isSuccessful) {
      throw StateError(
        'Configuration bundle request failed for serial $serial: HTTP ${response.statusCode}',
      );
    }
    if (body == null) {
      throw StateError(
        'Configuration bundle response is invalid for serial $serial',
      );
    }

    return DeviceConfigurationBundle.fromJson(body);
  }

  Map<String, dynamic>? _decodeBody(dynamic raw) {
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
}
