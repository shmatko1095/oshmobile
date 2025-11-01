// Example capability set (extend as needed)
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/domain/models/telemetry.dart';

abstract class ThermostatSignals {
  static const telemetrySignal = Signal<Telemetry>(Telemetry.alias);

  static const sensorCurrentAirTemperature = Signal<double>('chipTemp');
  static const sensorHumidity = Signal<double>('sensor.humidity');
  static const sensorPower = Signal<double>('sensor.power');
  static const sensorWaterInletTemp = Signal<double>('sensor.water_inlet_temp');
  static const sensorWaterOutletTemp = Signal<double>('sensor.water_outlet_temp');

  static const statsPower = Signal<int>('stats.heating_duty_24h');

  static const settingSwitchHeatingState = Signal<bool>('switch.heating.state');
  static const settingClimateMode = Signal<String>('climate.mode');

  static const targetC = Signal<double>('hvac.targetC');
  static const mode = Signal<String>('hvac.mode');
  static const powerW = Signal<double>('energy.powerW');
}
