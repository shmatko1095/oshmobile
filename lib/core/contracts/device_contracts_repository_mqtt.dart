import 'dart:async';

import 'package:oshmobile/core/contracts/device_contracts_models.dart';
import 'package:oshmobile/core/contracts/device_contracts_repository.dart';
import 'package:oshmobile/core/contracts/device_contracts_topics.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/stream_waiters.dart';

class DeviceContractsRepositoryMqtt implements DeviceContractsRepository {
  DeviceContractsRepositoryMqtt(
    this._jrpc,
    this._topics,
    this._deviceSn, {
    this.timeout = const Duration(seconds: 3),
  });

  final JsonRpcClient _jrpc;
  final DeviceContractsTopics _topics;
  final String _deviceSn;
  final Duration timeout;

  StreamController<DeviceContractsSnapshot>? _ctrl;
  StreamSubscription? _stateSub;
  int _refs = 0;
  bool _disposed = false;
  DeviceContractsSnapshot? _last;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final sub = _stateSub;
    final ctrl = _ctrl;

    _stateSub = null;
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
        if (!ctrl.isClosed) await ctrl.close();
      } catch (_) {}
    }
  }

  @override
  Future<DeviceContractsSnapshot> fetch({bool forceGet = false}) async {
    if (_disposed) throw StateError('DeviceContractsRepositoryMqtt is disposed');

    if (!forceGet) {
      final cached = _last;
      if (cached != null) return cached;

      try {
        return await firstWithTimeout<DeviceContractsSnapshot>(
          watch(),
          timeout,
          timeoutMessage: 'Timeout waiting for contracts state',
        );
      } on TimeoutException {
        // Fallback to explicit get below.
      }
    }

    final reqId = newReqId();
    final resp = await _jrpc.request(
      cmdTopic: _topics.cmd(_deviceSn),
      method: DeviceContractsTopics.methodGet,
      meta: JsonRpcMeta(
        schema: DeviceContractsTopics.schema,
        src: 'app',
        ts: DateTime.now().millisecondsSinceEpoch,
      ),
      reqId: reqId,
      data: null,
      timeout: timeout,
      timeoutMessage: 'Timeout waiting for contracts get response',
    );

    final data = resp.data;
    if (data == null) {
      throw StateError('Invalid contracts response');
    }
    if (resp.meta?.schema != null &&
        resp.meta!.schema != DeviceContractsTopics.schema) {
      throw StateError('Invalid contracts schema: ${resp.meta!.schema}');
    }

    final next = DeviceContractsSnapshot.fromJson(data);
    _emit(next);
    return next;
  }

  @override
  Stream<DeviceContractsSnapshot> watch() {
    if (_disposed) return Stream<DeviceContractsSnapshot>.empty();

    final existing = _ctrl;
    if (existing != null && !existing.isClosed) return existing.stream;

    late final StreamController<DeviceContractsSnapshot> ctrl;
    ctrl = StreamController<DeviceContractsSnapshot>.broadcast(
      onListen: () {
        _refs += 1;
        if (_refs > 1) return;
        _ensureSubscription();
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

  void _ensureSubscription() {
    if (_stateSub != null) return;

    _stateSub = _jrpc
        .notifications(
          _topics.state(_deviceSn),
          method: DeviceContractsTopics.methodState,
          schema: DeviceContractsTopics.schema,
        )
        .listen((notif) {
      final data = notif.data;
      if (data == null) return;
      try {
        final next = DeviceContractsSnapshot.fromJson(data);
        _emit(next);
      } catch (_) {}
    });
  }

  void _emit(DeviceContractsSnapshot snapshot) {
    _last = snapshot;
    final ctrl = _ctrl;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(snapshot);
    }
  }
}
