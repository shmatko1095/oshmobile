import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/profile/models/device_profile_bundle.dart';
import 'package:oshmobile/core/profile/profile_bundle_repository.dart';
import 'package:oshmobile/core/secrets/app_secrets.dart';

class ProfileBundleRepositoryImpl implements ProfileBundleRepository {
  const ProfileBundleRepositoryImpl({
    required ChopperClient client,
  }) : _client = client;

  final ChopperClient _client;

  @override
  Future<DeviceProfileBundle> fetchBundle({
    required String serial,
    required String modelId,
    Set<String> negotiatedSchemas = const <String>{},
  }) async {
    final uri = Uri.parse(
      '${AppSecrets.oshApiEndpoint}/mobile/devices/$serial/profile-bundle',
    ).replace(
      queryParameters: negotiatedSchemas.isEmpty
          ? null
          : <String, String>{
              'schemas': negotiatedSchemas.toList(growable: false).join(','),
            },
    );

    final request = Request('GET', uri, _client.baseUrl);
    final response = await _client.send<dynamic, dynamic>(request);
    final body = _decodeBody(response.body);
    if (!response.isSuccessful) {
      throw StateError(
        'Profile bundle request failed for model $modelId: HTTP ${response.statusCode}',
      );
    }
    if (body == null) {
      throw StateError(
        'Profile bundle response is invalid for model $modelId',
      );
    }

    return DeviceProfileBundle.fromJson(body).copyWith(
      serial: serial,
      negotiatedSchemas: negotiatedSchemas,
    );
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
