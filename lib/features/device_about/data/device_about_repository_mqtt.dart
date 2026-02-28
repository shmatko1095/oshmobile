import 'dart:async';

import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/device_topics_v1.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/device_state_models.dart';
import 'package:oshmobile/features/device_about/domain/repositories/device_about_repository.dart';

class DeviceAboutRepositoryMqtt implements DeviceAboutRepository {
  final JsonRpcClient _jrpc;
  final DeviceMqttTopicsV1 _topics;
  final DeviceRuntimeContracts _contracts;
  final String _deviceSn;

  StreamController<Map<String, dynamic>>? _ctrl;
  int _refs = 0;
  StreamSubscription? _sub;
  Map<String, dynamic>? _last;

  bool _disposed = false;

  DeviceAboutRepositoryMqtt({
    required JsonRpcClient jrpc,
    required DeviceMqttTopicsV1 topics,
    DeviceRuntimeContracts? contracts,
    required String deviceSn,
  })  : _jrpc = jrpc,
        _topics = topics,
        _contracts = contracts ?? DeviceRuntimeContracts(),
        _deviceSn = deviceSn;

  String get _domain => _contracts.device.methodDomain;
  String get _schema => _contracts.device.read.schema;
  String get _methodState => _contracts.device.read.method('state');

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

    final topic = _topics.state(_deviceSn, _domain);
    _sub = _jrpc
        .notifications(
      topic,
      method: _methodState,
    )
        .listen(
      (notif) {
        if (notif.meta.schema != _schema) return;
        final data = notif.data;
        if (data == null) return;

        final parsed = DeviceStatePayload.tryParse(data);
        if (parsed == null) return;

        _last = parsed.raw;
        final ctrl = _ctrl;
        if (ctrl != null && !ctrl.isClosed) {
          ctrl.add(parsed.raw);
        }
      },
      cancelOnError: false,
    );
  }
}
