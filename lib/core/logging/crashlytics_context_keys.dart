final class CrashlyticsContextKeys {
  CrashlyticsContextKeys._();

  static const sessionMode = 'session_mode';
  static const authProvider = 'auth_provider';
  static const startupPhase = 'startup_phase';
  static const policyStatus = 'policy_status';
  static const mqttConnected = 'mqtt_connected';
  static const selectedDeviceType = 'selected_device_type';
  static const bleFlowStep = 'ble_flow_step';

  static const all = <String>[
    sessionMode,
    authProvider,
    startupPhase,
    policyStatus,
    mqttConnected,
    selectedDeviceType,
    bleFlowStep,
  ];

  static const logoutResetKeys = <String>[
    sessionMode,
    authProvider,
    mqttConnected,
    selectedDeviceType,
    bleFlowStep,
  ];
}

final class CrashlyticsContextValues {
  CrashlyticsContextValues._();

  static const none = 'none';
  static const unknown = 'unknown';
  static const demo = 'demo';
  static const real = 'real';
}
