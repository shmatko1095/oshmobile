/// Domain-facing telemetry contract (alias → value diffs).
abstract class TelemetryRepository {
  Future<void> subscribe(String deviceId);

  Future<void> unsubscribe(String deviceId);

  /// Stream emits alias-keyed diffs, e.g., {'hvac.targetC': 21.5}
  Stream<Map<String, dynamic>> watchAliases(String deviceId);
}
