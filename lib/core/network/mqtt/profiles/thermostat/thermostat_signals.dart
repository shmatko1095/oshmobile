// Example capability set (extend as needed).
abstract class ThermostatSignals {
  static const String telemetrySignal = 'sensor.temperature';

  static const String sensorCurrentAirTemperature = 'sensor.temperature';
  static const String sensorHumidity = 'sensor.humidity';
  static const String sensorPower = 'sensor.power';
  static const String sensorWaterInletTemp = 'sensor.water_inlet_temp';
  static const String sensorWaterOutletTemp = 'sensor.water_outlet_temp';

  static const String statsPower = 'stats.heating_duty_24h';

  static const String settingSwitchHeatingState = 'switch.heating.state';
  static const String settingClimateMode = 'climate.mode';

  static const String targetC = 'hvac.targetC';
  static const String mode = 'hvac.mode';
  static const String powerW = 'energy.powerW';
}
