import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/control_repository.dart';

class DisableRtStream {
  final ControlRepository control;

  const DisableRtStream(this.control);

  /// Ask device to stop RT telemetry.
  Future<void> call() {
    // value = true (payload can be ignored on FW side if you prefer)
    return control.send<bool>(DeviceCommands.disableRt, true);
  }
}
