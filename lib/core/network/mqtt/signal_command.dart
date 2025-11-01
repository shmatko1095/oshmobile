/// Semantic keys used by UI/domain without knowing transport topics.
class Signal<T> {
  final String alias; // e.g., 'hvac.targetC'
  const Signal(this.alias);
}

class Command<T> {
  final String alias; // e.g., 'hvac.setTargetC'
  const Command(this.alias);
}

abstract class DeviceCommands {
  /// Enable real-time stream with a given interval in milliseconds.
  static const enableRt = Command<int>('rt.enable');

  /// Disable real-time stream (we'll send `true` as value).
  static const disableRt = Command<bool>('rt.disable');
}
