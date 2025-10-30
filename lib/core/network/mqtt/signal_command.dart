/// Semantic keys used by UI/domain without knowing transport topics.
class Signal<T> {
  final String alias; // e.g., 'hvac.targetC'
  const Signal(this.alias);
}

class Command<T> {
  final String alias; // e.g., 'hvac.setTargetC'
  const Command(this.alias);
}

// Example capability set (extend as needed)
abstract class ThermostatSignals {
  static const targetC = Signal<double>('hvac.targetC');
  static const mode = Signal<String>('hvac.mode');
  static const powerW = Signal<double>('energy.powerW');
}

abstract class ThermostatCommands {
  static const setTargetC = Command<double>('hvac.setTargetC');
  static const setMode = Command<String>('hvac.setMode');
}

abstract class DeviceCommands {
  /// Enable real-time stream with a given interval in milliseconds.
  static const enableRt = Command<int>('rt.enable');

  /// Disable real-time stream (we'll send `true` as value).
  static const disableRt = Command<bool>('rt.disable');
}
