import 'dart:async';

import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/features/sensors/domain/repositories/sensors_repository.dart';

class DeviceSensorsApiImpl implements DeviceSensorsApi {
  final SensorsRepository _repo;
  SensorsState? _last;
  StreamSubscription<SensorsState>? _sub;
  bool _started = false;
  bool _disposed = false;

  DeviceSensorsApiImpl({required SensorsRepository repo}) : _repo = repo;

  Future<void> start() async {
    if (_disposed || _started) return;
    _started = true;

    _sub = _repo.watchState().listen(
      (state) {
        _last = state;
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  @override
  SensorsState? get current => _last;

  @override
  Stream<SensorsState> watch() {
    return Stream<SensorsState>.multi((controller) {
      final cur = _last;
      if (cur != null) {
        controller.add(cur);
      }

      final sub = _repo.watchState().listen(
        (state) {
          _last = state;
          controller.add(state);
        },
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<SensorsState> get({bool force = false}) async {
    final state = await _repo.fetchAll(forceGet: force);
    _last = state;
    return state;
  }

  @override
  Future<void> patch(SensorsPatch patch) => _repo.patch(patch);

  @override
  Future<void> save(SensorsSetPayload payload) => _repo.saveAll(payload);

  @override
  Future<void> rename({
    required String id,
    required String name,
  }) {
    return patch(SensorsPatchRename(id: id, name: name));
  }

  @override
  Future<void> setReference({
    required String id,
  }) {
    return patch(SensorsPatchSetRef(id: id));
  }

  @override
  Future<void> setTempCalibration({
    required String id,
    required double value,
  }) {
    return patch(SensorsPatchSetTempCalibration(id: id, value: value));
  }

  @override
  Future<void> remove({
    required String id,
    bool? leave,
  }) {
    return patch(SensorsPatchRemove(id: id, leave: leave));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    try {
      await _sub?.cancel();
    } catch (_) {}
  }
}
