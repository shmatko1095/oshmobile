import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/features/device_about/domain/repositories/device_about_repository.dart';

class DeviceAboutRepositoryMqtt implements DeviceAboutRepository {
  final DeviceMqttRepo _mqtt;
  final DeviceMqttTopicsV1 _topics;
  final String _deviceSn;

  StreamController<Map<String, dynamic>>? _ctrl;
  int _refs = 0;
  StreamSubscription? _sub;
  Map<String, dynamic>? _last;

  bool _disposed = false;

  DeviceAboutRepositoryMqtt({
    required DeviceMqttRepo mqtt,
    required DeviceMqttTopicsV1 topics,
    required String deviceSn,
  })  : _mqtt = mqtt,
        _topics = topics,
        _deviceSn = deviceSn;

  /// Best-effort cleanup when device scope is disposed.
  /// Not part of DeviceAboutRepository interface on purpose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final sub = _sub;
    final ctrl = _ctrl;

    _sub = null;
    _ctrl = null;
    _refs = 0;
    _last = null;

    if (sub != null) {
      try {
        await sub.cancel();
      } catch (_) {}
    }
    if (ctrl != null) {
      try {
        await ctrl.close();
      } catch (_) {}
    }
  }

  @override
  Stream<Map<String, dynamic>> watchState() {
    if (_disposed) return Stream<Map<String, dynamic>>.empty();

    final existing = _ctrl;
    if (existing != null && !existing.isClosed) return existing.stream;

    late final StreamController<Map<String, dynamic>> ctrl;
    ctrl = StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        _refs += 1;
        if (_refs > 1) return;

        _ensureSubscription();

        final cached = _last;
        if (cached != null) {
          ctrl.add(cached);
        }
      },
      onCancel: () async {
        _refs -= 1;
        if (_refs <= 0) {
          _refs = 0;

          final sub = _sub;
          _sub = null;
          if (sub != null) {
            try {
              await sub.cancel();
            } catch (_) {}
          }

          final c = _ctrl;
          _ctrl = null;
          if (c != null && !c.isClosed) {
            await c.close();
          }
        }
      },
    );

    _ctrl = ctrl;
    return ctrl.stream;
  }

  void _ensureSubscription() {
    if (_sub != null) return;

    final topic = _topics.state(_deviceSn, 'device');
    _sub = _mqtt.subscribeJson(topic).listen(
      (msg) {
        _last = msg.payload;
        final ctrl = _ctrl;
        if (ctrl != null && !ctrl.isClosed) {
          ctrl.add(msg.payload);
        }
      },
      cancelOnError: false,
    );
  }
}
