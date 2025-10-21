import 'package:flutter_bloc/flutter_bloc.dart';

import 'device_state_cubit.dart';

abstract class CommandRepository {
  Future<void> send(String deviceId, String command, {Map<String, dynamic>? args});
}

// ===== Mock commands: меняем значения в моковой телеметрии
class CommandRepositoryMock implements CommandRepository {
  final TelemetryRepositoryMock telemetry;

  CommandRepositoryMock(this.telemetry);

  @override
  Future<void> send(String deviceId, String command, {Map<String, dynamic>? args}) async {
    // простая маршрутизация
    if (command == 'switch.heating.set') {
      final v = (args?['state'] as bool?) ?? false;
      telemetry.setSwitch(deviceId, v);
    }
    // можно добавить обработку climate.set_target_temperature и т.п.
  }
}

sealed class ActionState {
  const ActionState();
}

class ActionIdle extends ActionState {
  const ActionIdle();
}

class ActionRunning extends ActionState {
  const ActionRunning();
}

class ActionDone extends ActionState {
  const ActionDone();
}

class ActionError extends ActionState {
  final String message;

  const ActionError(this.message);
}

class DeviceActionsCubit extends Cubit<ActionState> {
  final CommandRepository commands;

  DeviceActionsCubit(this.commands) : super(const ActionIdle());

  Future<void> sendCommand(String deviceId, String command, {Map<String, dynamic>? args}) async {
    emit(const ActionRunning());
    try {
      await commands.send(deviceId, command, args: args);
      emit(const ActionDone());
      emit(const ActionIdle());
    } catch (e) {
      emit(ActionError(e.toString()));
    }
  }
}
