import 'dart:async';

import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/utils/latest_wins_gate.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/stream_waiters.dart';
import 'package:oshmobile/core/utils/superseded_exception.dart';
import 'package:oshmobile/features/settings/data/settings_jsonrpc_codec.dart';
import 'package:oshmobile/features/settings/data/settings_topics.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryMqtt implements SettingsRepository {
  final JsonRpcClient _jrpc;
  final SettingsTopics _topics;
  final DeviceRuntimeContracts _contracts;
  final String _deviceSn;
  final Duration timeout;

  StreamController<SettingsSnapshot>? _ctrl;
  int _refs = 0;

  StreamSubscription? _stateSub;
  StreamSubscription? _evtSub;

  SettingsSnapshot? _last;

  // Latest-wins gate for save operations.
  final LatestWinsGate _latest = LatestWinsGate();

  bool _disposed = false;

  SettingsRepositoryMqtt(
    this._jrpc,
    this._topics,
    this._deviceSn, {
    DeviceRuntimeContracts? contracts,
    this.timeout = const Duration(seconds: 6),
  }) : _contracts = contracts ?? DeviceRuntimeContracts();

  String get _schema => _contracts.settings.read.schema;
  String get _domain => _contracts.settings.methodDomain;
  String get _methodState => _contracts.settings.read.method('state');
  String get _methodChanged => _contracts.settings.read.method('changed');
  String get _methodGet => _contracts.settings.read.method('get');
  String get _methodSet => _contracts.settings.set.method('set');
  String get _methodPatch => _contracts.settings.patch.method('patch');
  Set<String> get _responseSchemas => <String>{
        _contracts.settings.read.schema,
        _contracts.settings.patch.schema,
        _contracts.settings.set.schema,
      };

  /// Best-effort cleanup when device scope is disposed.
  /// Not part of SettingsRepository interface on purpose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final stateSub = _stateSub;
    final evtSub = _evtSub;
    final ctrl = _ctrl;

    _stateSub = null;
    _evtSub = null;
    _ctrl = null;
    _refs = 0;
    _last = null;
    _latest.clear();

    if (stateSub != null) {
      try {
        await stateSub.cancel();
      } catch (_) {}
    }
    if (evtSub != null) {
      try {
        await evtSub.cancel();
      } catch (_) {}
    }
    if (ctrl != null) {
      try {
        if (!ctrl.isClosed) await ctrl.close();
      } catch (_) {}
    }
  }

  // -------------------- Public API --------------------

  @override
  Future<SettingsSnapshot> fetchAll({bool forceGet = false}) async {
    if (_disposed) throw StateError('SettingsRepositoryMqtt is disposed');

    if (!forceGet) {
      final cached = _last;
      if (cached != null) return cached;

      try {
        final snap = await firstWithTimeout<SettingsSnapshot>(
          watchSnapshot(),
          timeout,
          timeoutMessage: 'Timeout waiting for settings state',
        );
        return snap;
      } on TimeoutException {
        // Fallback: explicit JSON-RPC get.
      }
    }

    final reqId = newReqId();
    final resp = await _request(
      method: _methodGet,
      reqId: reqId,
      data: null,
      timeoutMessage: 'Timeout waiting for settings get response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap == null) {
      throw StateError('Invalid settings response');
    }
    _emitSnapshot(snap);
    return snap;
  }

  @override
  Future<void> saveAll(
    SettingsSnapshot snapshot, {
    String? reqId,
  }) async {
    if (_disposed) throw StateError('SettingsRepositoryMqtt is disposed');

    final id = reqId ?? newReqId();
    final data = SettingsJsonRpcCodec.encodeBody(snapshot);

    final latest = _latest.start(_latestKey('save'));

    final resp = await _request(
      method: _methodSet,
      reqId: id,
      data: data,
      timeoutMessage: 'Timeout waiting for settings save response',
      cancel: latest.cancelled,
      cancelError: const SupersededException('Settings save superseded'),
    );

    if (!_latest.isCurrent(latest)) {
      throw const SupersededException('Settings save superseded');
    }

    final snap = _snapshotFromResponse(resp);
    if (snap != null) _emitSnapshot(snap);
  }

  @override
  Future<void> patch(Map<String, dynamic> patch, {String? reqId}) async {
    if (_disposed) throw StateError('SettingsRepositoryMqtt is disposed');

    final id = reqId ?? newReqId();
    final data = SettingsJsonRpcCodec.encodePatch(patch);

    final resp = await _request(
      method: _methodPatch,
      reqId: id,
      data: data,
      timeoutMessage: 'Timeout waiting for settings patch response',
    );

    final snap = _snapshotFromResponse(resp);
    if (snap != null) _emitSnapshot(snap);
  }

  @override
  Stream<SettingsSnapshot> watchSnapshot() {
    if (_disposed) return Stream<SettingsSnapshot>.empty();

    final existing = _ctrl;
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    late final StreamController<SettingsSnapshot> ctrl;

    ctrl = StreamController<SettingsSnapshot>.broadcast(
      onListen: () {
        _refs += 1;
        if (_refs > 1) return;

        _ensureStateSubscription();

        final cached = _last;
        if (cached != null) {
          ctrl.add(cached);
        }
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

  // -------------------- MQTT subscriptions --------------------

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

      final snap = SettingsJsonRpcCodec.decodeBody(data);
      if (snap == null) return;
      _emitSnapshot(snap);
    });

    final evtTopic = _topics.evt(_deviceSn);
    _evtSub = _jrpc
        .notifications(
      evtTopic,
      method: _methodChanged,
    )
        .listen((notif) {
      if (notif.meta.schema != _schema) return;
      final data = notif.data;
      if (data == null) return;

      final snap = SettingsJsonRpcCodec.decodeBody(data);
      if (snap == null) return;
      _emitSnapshot(snap);
    });
  }

  // -------------------- JSON-RPC helpers --------------------

  void _emitSnapshot(SettingsSnapshot snap) {
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

  String _latestKey(String op) => op;

  Future<JsonRpcResponse> _request({
    required String method,
    required String reqId,
    required Map<String, dynamic>? data,
    required String timeoutMessage,
    Future<void>? cancel,
    Object? cancelError,
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
      cancel: cancel,
      cancelError: cancelError,
    );
  }

  SettingsSnapshot? _snapshotFromResponse(JsonRpcResponse resp) {
    final data = resp.data;
    if (data == null) return null;

    if (resp.meta != null && !_responseSchemas.contains(resp.meta!.schema)) {
      return null;
    }

    return SettingsJsonRpcCodec.decodeBody(data);
  }
}
