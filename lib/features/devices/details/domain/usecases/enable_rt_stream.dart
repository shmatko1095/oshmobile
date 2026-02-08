import 'package:oshmobile/core/network/mqtt/signal_command.dart';

import '../repositories/control_repository.dart';

class EnableRtStream {
  final ControlRepository control;

  const EnableRtStream(this.control);

  /// Ask device to start publishing RT telemetry at [interval].
  Future<void> call({Duration interval = const Duration(seconds: 1)}) {
    // value = interval in milliseconds (adjust if your FW expects seconds)
    return control.send<int>(DeviceCommands.enableRt, interval.inMilliseconds);
  }
}
