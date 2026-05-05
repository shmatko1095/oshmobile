import 'package:chopper/chopper.dart';
import 'package:oshmobile/core/configuration/configuration_bundle_repository.dart';
import 'package:oshmobile/core/configuration/models/device_configuration_bundle.dart';
import 'package:oshmobile/core/network/rest_response_error_mapper.dart';
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
    if (!response.isSuccessful) {
      throw RestResponseErrorMapper.toServerException(response);
    }
    final body = RestResponseErrorMapper.decodeMap(response.body);
    if (body == null) {
      throw StateError(
        'Configuration bundle response is invalid for serial $serial',
      );
    }

    return DeviceConfigurationBundle.fromJson(body);
  }
}
