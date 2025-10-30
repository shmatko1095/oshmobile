part of 'global_mqtt_cubit.dart';

@immutable
sealed class GlobalMqttState {
  const GlobalMqttState();
}

final class MqttDisconnected extends GlobalMqttState {
  const MqttDisconnected();
}

final class MqttConnecting extends GlobalMqttState {
  const MqttConnecting();
}

final class MqttConnected extends GlobalMqttState {
  const MqttConnected();
}

final class MqttError extends GlobalMqttState {
  final String message;

  const MqttError(this.message);
}
