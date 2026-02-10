import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';

/// Domain-facing telemetry contract (alias → value diffs).
abstract class TelemetryRepository {
  /// Fetch current telemetry snapshot via JSON-RPC get.
  Future<TelemetryState> fetch();

  /// Send telemetry.set (not allowed by FW, expected to return NotAllowed).
  Future<void> set({String? reqId});

  /// Send telemetry.patch (not allowed by FW, expected to return NotAllowed).
  Future<void> patch({String? reqId});

  Future<void> subscribe();

  Future<void> unsubscribe();

  /// Stream emits alias-keyed diffs, e.g., {'hvac.targetC': 21.5}
  Stream<Map<String, dynamic>> watchAliases();
}
