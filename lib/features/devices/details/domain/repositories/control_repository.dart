import 'package:oshmobile/core/network/mqtt/signal_command.dart';

abstract class ControlRepository {
  Future<void> send<T>(Command<T> cmd, T value, {String? corrId});
}
