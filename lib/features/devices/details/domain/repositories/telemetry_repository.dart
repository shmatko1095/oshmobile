import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';

/// Domain-facing telemetry contract.
abstract class TelemetryRepository {
  TelemetryState? get currentState;

  /// Fetch current telemetry snapshot via JSON-RPC get.
  Future<TelemetryState> fetch();

  Future<void> subscribe();

  Future<void> unsubscribe();

  /// Stream emits canonical telemetry snapshots from `telemetry.state`.
  Stream<TelemetryState> watchState();
}
