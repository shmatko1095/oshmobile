import 'dart:async';

import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/device_state_models.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/features/device_state/data/device_state_topics.dart';
import 'package:oshmobile/features/device_state/domain/repositories/device_state_repository.dart';

class DeviceStateRepositoryMqtt implements DeviceStateRepository {
  final JsonRpcClient _jrpc;
  final DeviceStateTopics _topics;
  final DeviceRuntimeContracts _contracts;
  final String _deviceSn;
  final Duration timeout;

  StreamController<DeviceStatePayload>? _ctrl;
  int _refs = 0;
  StreamSubscription? _stateSub;

  DeviceStatePayload? _last;
  bool _disposed = false;

  DeviceStateRepositoryMqtt(
    this._jrpc,
    this._topics,
    this._deviceSn, {
    DeviceRuntimeContracts? contracts,
    this.timeout = const Duration(seconds: 6),
  }) : _contracts = contracts ?? DeviceRuntimeContracts();

  String get _schema => _contracts.device.read.schema;
  String get _domain => _contracts.device.methodDomain;
  String get _methodState => _contracts.device.read.method('state');
  String get _methodGet => _contracts.device.read.method('get');
  String get _methodSet => _contracts.device.set.method('set');
  String get _methodPatch => _contracts.device.patch.method('patch');

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final stateSub = _stateSub;
    final ctrl = _ctrl;

    _stateSub = null;
    _ctrl = null;
    _refs = 0;
    _last = null;

    if (stateSub != null) {
      try {
        await stateSub.cancel();
      } catch (_) {}
    }
    if (ctrl != null) {
      try {
        if (!ctrl.isClosed) await ctrl.close();
      } catch (_) {}
    }
  }

  @override
  Future<DeviceStatePayload> fetch() async {
    if (_disposed) throw StateError('DeviceStateRepositoryMqtt is disposed');

    final reqId = newReqId();
    final resp = await _request(
      method: _methodGet,
      reqId: reqId,
      data: null,
      timeoutMessage: 'Timeout waiting for device get response',
    );

    final data = resp.data;
    if (data == null) throw StateError('Invalid device state response');
    if (resp.meta != null && resp.meta!.schema != _schema) {
      throw StateError('Invalid device state schema: ${resp.meta!.schema}');
    }

    final parsed = DeviceStatePayload.tryParse(data);
    if (parsed == null) throw StateError('Invalid device state payload');
    _emitSnapshot(parsed);
    return parsed;
  }

  @override
  Future<void> set({String? reqId}) async {
    if (_disposed) throw StateError('DeviceStateRepositoryMqtt is disposed');
    final id = reqId ?? newReqId();
    await _request(
      method: _methodSet,
      reqId: id,
      data: const <String, dynamic>{},
      timeoutMessage: 'Timeout waiting for device set response',
    );
  }

  @override
  Future<void> patch({String? reqId}) async {
    if (_disposed) throw StateError('DeviceStateRepositoryMqtt is disposed');
    final id = reqId ?? newReqId();
    await _request(
      method: _methodPatch,
      reqId: id,
      data: const <String, dynamic>{},
      timeoutMessage: 'Timeout waiting for device patch response',
    );
  }

  @override
  Stream<DeviceStatePayload> watchState() {
    if (_disposed) return Stream<DeviceStatePayload>.empty();

    final existing = _ctrl;
    if (existing != null && !existing.isClosed) return existing.stream;

    late final StreamController<DeviceStatePayload> ctrl;
    ctrl = StreamController<DeviceStatePayload>.broadcast(
      onListen: () {
        _refs += 1;
        if (_refs > 1) return;
        _ensureStateSubscription();
        final cached = _last;
        if (cached != null) ctrl.add(cached);
      },
      onCancel: () async {
        _refs -= 1;
        if (_refs <= 0) {
          _refs = 0;
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

  void _ensureStateSubscription() {
    if (_stateSub != null) return;

    final topic = _topics.state(_deviceSn);
    _stateSub = _jrpc
        .notifications(
      topic,
      method: _methodState,
    )
        .listen((notif) {
      if (notif.meta.schema != _schema) return;
      final data = notif.data;
      if (data == null) return;

      final snap = DeviceStatePayload.tryParse(data);
      if (snap == null) return;
      _emitSnapshot(snap);
    });
  }

  void _emitSnapshot(DeviceStatePayload snap) {
    _last = snap;
    final ctrl = _ctrl;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(snap);
    }
  }

  JsonRpcMeta _meta() => JsonRpcMeta(
        schema: _schema,
        src: 'app',
        ts: DateTime.now().millisecondsSinceEpoch,
      );

  Future<JsonRpcResponse> _request({
    required String method,
    required String reqId,
    required Map<String, dynamic>? data,
    required String timeoutMessage,
  }) async {
    return _jrpc.request(
      cmdTopic: _topics.cmd(_deviceSn),
      method: method,
      meta: _meta(),
      reqId: reqId,
      data: data,
      domain: _domain,
      timeout: timeout,
      timeoutMessage: timeoutMessage,
    );
  }
}
