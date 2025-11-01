import 'package:oshmobile/core/network/mqtt/signal_command.dart';

abstract class ThermostatCommands {
  // static const setTargetC = Command<double>('hvac.setTargetC');
  // static const setMode = Command<String>('hvac.setMode');

  static const switchHeatingSet = Command<bool>('switch.heating.set');
}
