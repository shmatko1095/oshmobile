import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';

abstract class SensorsRepository {
  /// Fetch full sensors metadata snapshot.
  Future<SensorsState> fetchAll({bool forceGet = false});

  /// Replace metadata for all current sensors (sensors.set).
  Future<void> saveAll(SensorsSetPayload payload, {String? reqId});

  /// Apply patch operation (sensors.patch).
  Future<void> patch(SensorsPatch patch, {String? reqId});

  /// Stream of retained sensors state.
  Stream<SensorsState> watchState();
}
