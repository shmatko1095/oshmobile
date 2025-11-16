class AppConfig {
  /// Issuer (realm) URL, used by OIDC / Keycloak.
  final String issuerUri;

  /// Base URL for the auth frontend (Keycloak).
  final String frontendUrl;

  /// Keycloak realm name.
  final String usersRealmId;

  /// Base URL for your osh-backend REST API.
  final String oshApiEndpoint;

  /// MQTT broker host used by the mobile app.
  final String oshMqttEndpointUrl;

  /// MQTT broker port used by the mobile app.
  final int oshMqttEndpointPort;

  /// Tenant / namespace for your devices.
  final String devicesTenantId;

  const AppConfig({
    required this.issuerUri,
    required this.frontendUrl,
    required this.usersRealmId,
    required this.oshApiEndpoint,
    required this.oshMqttEndpointUrl,
    required this.oshMqttEndpointPort,
    required this.devicesTenantId,
  });

  const AppConfig.dev()
      : issuerUri = 'https://auth.oshhome.com/realms/users-dev',
        frontendUrl = 'https://auth.oshhome.com',
        usersRealmId = 'users-dev',
        oshApiEndpoint = 'https://api.oshhome.com/v1',
        oshMqttEndpointUrl = 'mqtt.oshhome.com',
        oshMqttEndpointPort = 31883,
        devicesTenantId = 'devices-dev';

  factory AppConfig.fromEnv() {
    return AppConfig(
      issuerUri: const String.fromEnvironment(
        'ISSUER_URI',
        defaultValue: 'https://auth.oshhome.com/realms/users-dev',
      ),
      frontendUrl: const String.fromEnvironment(
        'FRONTEND_URL',
        defaultValue: 'https://auth.oshhome.com',
      ),
      usersRealmId: const String.fromEnvironment(
        'REALM',
        defaultValue: 'users-dev',
      ),
      oshApiEndpoint: const String.fromEnvironment(
        'OSH_API_ENDPOINT',
        defaultValue: 'https://api.oshhome.com/v1',
      ),
      oshMqttEndpointUrl: const String.fromEnvironment(
        'OSH_MQTT_ENDPOINT_URL',
        defaultValue: 'mqtt.oshhome.com',
      ),
      oshMqttEndpointPort: int.fromEnvironment(
        'OSH_MQTT_ENDPOINT_PORT',
        defaultValue: 31883,
      ),
      devicesTenantId: const String.fromEnvironment(
        'TENANT_ID',
        defaultValue: 'devices-dev',
      ),
    );
  }
}
