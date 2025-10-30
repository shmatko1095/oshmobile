import 'signal_command.dart';

/// Resolves semantic aliases to concrete MQTT topics.
abstract class TopicsResolver {
  String topicOfSignal(Signal<dynamic> s, {required String deviceId});

  String topicOfCommand(Command<dynamic> c, {required String deviceId});
}

/// Example resolver for thermostat devices using your v1 pathing.
/// Adjust mapping to match your firmware topics.
class ThermostatTopicsResolver implements TopicsResolver {
  ThermostatTopicsResolver(this.tenantId);

  final String tenantId;

  @override
  String topicOfSignal(Signal s, {required String deviceId}) {
    switch (s.alias) {
      case 'hvac.targetC':
        return 'v1/tenants/$tenantId/devices/$deviceId/telemetry/hvac/target';
      case 'hvac.mode':
        return 'v1/tenants/$tenantId/devices/$deviceId/telemetry/hvac/mode';
      case 'energy.powerW':
        return 'v1/tenants/$tenantId/devices/$deviceId/telemetry/energy/powerW';
      default:
        return 'v1/tenants/$tenantId/devices/$deviceId/telemetry/${s.alias.replaceAll('.', '/')}';
    }
  }

  @override
  String topicOfCommand(Command c, {required String deviceId}) {
// Using cmd/inbox pattern with action == alias by default.
// If some commands require a dedicated topic, special‑case here.
    return 'v1/tenants/$tenantId/devices/$deviceId/cmd/inbox';
  }
}
