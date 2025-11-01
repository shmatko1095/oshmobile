import 'package:oshmobile/core/network/mqtt/signal_command.dart';

/// Resolves semantic aliases to concrete MQTT topics.
abstract class TopicsResolver {
  String topicOfSignal(Signal<dynamic> s, {required String deviceId});

  String topicOfCommand(Command<dynamic> c, {required String deviceId});
}
