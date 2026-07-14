part of 'device_facade.dart';

abstract interface class DeviceSensorsApi {
  SensorsState? get current;

  Stream<SensorsState> watch();

  Future<SensorsState> get({bool force = false});

  Future<void> patch(SensorsPatch patch);

  Future<void> save(SensorsSetPayload payload);

  Future<void> rename({
    required String id,
    required String name,
  });

  Future<void> setReference({
    required String id,
  });

  Future<void> setPairing({
    required bool enabled,
    int? timeoutSec,
  });

  Future<void> remove({
    required String id,
    bool? leave,
  });
}
