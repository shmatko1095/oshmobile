import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/features/device_about/domain/repositories/device_about_repository.dart';

class DeviceAboutRepositoryMqtt implements DeviceAboutRepository {
  final DeviceMqttRepo _mqtt;
  final DeviceMqttTopicsV1 _topics;

  // per-device broadcast + refcount + underlying stream subs
  final Map<String, StreamController<Map<String, dynamic>>> _ctrls = {};
  final Map<String, int> _refs = {};
  final Map<String, StreamSubscription> _subs = {};
  final Map<String, Map<String, dynamic>> _last = {};

  bool _disposed = false;

  DeviceAboutRepositoryMqtt(this._mqtt, this._topics);

  /// Best-effort cleanup when session scope is disposed.
  /// Not part of DeviceAboutRepository interface on purpose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final subs = _subs.values.toList(growable: false);
    final ctrls = _ctrls.values.toList(growable: false);

    _subs.clear();
    _refs.clear();
    _ctrls.clear();
    _last.clear();

    for (final s in subs) {
      try {
        await s.cancel();
      } catch (_) {}
    }
    for (final c in ctrls) {
      try {
        await c.close();
      } catch (_) {}
    }
  }

  @override
  Stream<Map<String, dynamic>> watchState(String deviceSn) {
    if (_disposed) return Stream<Map<String, dynamic>>.empty();

    final existing = _ctrls[deviceSn];
    if (existing != null && !existing.isClosed) return existing.stream;

    late final StreamController<Map<String, dynamic>> ctrl;
    ctrl = StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        _refs[deviceSn] = (_refs[deviceSn] ?? 0) + 1;
        if (_refs[deviceSn]! > 1) return;

        _ensureSubscription(deviceSn);

        final cached = _last[deviceSn];
        if (cached != null) {
          ctrl.add(cached);
        }
      },
      onCancel: () async {
        _refs[deviceSn] = (_refs[deviceSn] ?? 1) - 1;
        if (_refs[deviceSn]! <= 0) {
          _refs.remove(deviceSn);

          final sub = _subs.remove(deviceSn);
          if (sub != null) {
            try {
              await sub.cancel();
            } catch (_) {}
          }

          final c = _ctrls.remove(deviceSn);
          if (c != null && !c.isClosed) {
            await c.close();
          }
        }
      },
    );

    _ctrls[deviceSn] = ctrl;
    return ctrl.stream;
  }

  void _ensureSubscription(String deviceSn) {
    if (_subs.containsKey(deviceSn)) return;

    final topic = _topics.state(deviceSn, 'device');
    _subs[deviceSn] = _mqtt.subscribeJson(topic).listen(
      (msg) {
        _last[deviceSn] = msg.payload;
        final ctrl = _ctrls[deviceSn];
        if (ctrl != null && !ctrl.isClosed) {
          ctrl.add(msg.payload);
        }
      },
      cancelOnError: false,
    );
  }
}
