import 'dart:async';

import 'package:oshmobile/core/contracts/bundled_contract_defaults.dart';
import 'package:oshmobile/core/contracts/device_runtime_contracts.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_topics.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';

class TelemetryJsonRpcCodec {
  // Legacy v1 defaults kept only for tests and compatibility helpers.
  static final _contract = BundledContractDefaults.v1.telemetry;

  static String get schema => _contract.schema;
  static String get domain => _contract.methodDomain;

  static String methodOf(String op) => _contract.method(op);

  static String get methodState => methodOf('state');
  static String get methodGet => methodOf('get');
  static String get methodSet => methodOf('set');
  static String get methodPatch => methodOf('patch');
}

class MqttTelemetryRepositoryImpl implements TelemetryRepository {
  MqttTelemetryRepositoryImpl({
    required JsonRpcClient jrpc,
    required TelemetryTopics topics,
    DeviceRuntimeContracts? contracts,
    required String deviceSn,
    this.pollInterval = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 6),
  })  : _jrpc = jrpc,
        _topics = topics,
        _contracts = contracts ?? DeviceRuntimeContracts(),
        _deviceSn = deviceSn;

  final JsonRpcClient _jrpc;
  final TelemetryTopics _topics;
  final DeviceRuntimeContracts _contracts;
  final String _deviceSn;
  final Duration pollInterval;
  final Duration timeout;

  StreamController<TelemetryState>? _ctrl;
  StreamSubscription? _sub;
  int _refs = 0;

  Timer? _pollTimer;
  bool _pollInFlight = false;

  TelemetryState? _telemetry;
  bool _disposed = false;

  String get _telemetrySchema => _contracts.telemetry.read.schema;
  String get _telemetryDomain => _contracts.telemetry.methodDomain;
  String get _telemetryMethodState => _contracts.telemetry.read.method('state');
  String get _telemetryMethodGet => _contracts.telemetry.read.method('get');
  String get _telemetryMethodSet => _contracts.telemetry.set.method('set');
  String get _telemetryMethodPatch =>
      _contracts.telemetry.patch.method('patch');

  @override
  TelemetryState? get currentState => _telemetry;

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

    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInFlight = false;
    _telemetry = null;

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
  Future<TelemetryState> fetch() async {
    if (_disposed) throw StateError('MqttTelemetryRepositoryImpl is disposed');

    final reqId = newReqId();
    final resp = await _request(
      method: _telemetryMethodGet,
      reqId: reqId,
      data: null,
      timeoutMessage: 'Timeout waiting for telemetry get response',
    );

    final data = resp.data;
    if (data == null) throw StateError('Invalid telemetry response');
    if (resp.meta != null && resp.meta!.schema != _telemetrySchema) {
      throw StateError('Invalid telemetry schema: ${resp.meta!.schema}');
    }

    final parsed = TelemetryState.fromJson(data);
    if (parsed == null) throw StateError('Invalid telemetry payload');

    _emitState(parsed);
    return parsed;
  }

  @override
  Future<void> set({String? reqId}) async {
    if (_disposed) throw StateError('MqttTelemetryRepositoryImpl is disposed');
    final id = reqId ?? newReqId();
    await _request(
      method: _telemetryMethodSet,
      reqId: id,
      data: const <String, dynamic>{},
      timeoutMessage: 'Timeout waiting for telemetry set response',
    );
  }

  @override
  Future<void> patch({String? reqId}) async {
    if (_disposed) throw StateError('MqttTelemetryRepositoryImpl is disposed');
    final id = reqId ?? newReqId();
    await _request(
      method: _telemetryMethodPatch,
      reqId: id,
      data: const <String, dynamic>{},
      timeoutMessage: 'Timeout waiting for telemetry patch response',
    );
  }

  @override
  Future<void> subscribe() async {
    if (_disposed) return;

    _refs += 1;
    if (_refs > 1) return;

    final ctrl = _ensureController();
    _sub = _jrpc
        .notifications(
      _topics.stateTelemetry(_deviceSn),
      method: _telemetryMethodState,
    )
        .listen((notif) {
      if (notif.meta.schema != _telemetrySchema) return;
      final data = notif.data;
      if (data == null) return;

      final parsed = TelemetryState.fromJson(data);
      if (parsed == null) return;

      _emitState(parsed, ctrl: ctrl);
    });

    _startPolling();
  }

  @override
  Future<void> unsubscribe() async {
    if (_disposed) return;

    _refs -= 1;
    if (_refs > 0) return;

    _refs = 0;

    final sub = _sub;
    _sub = null;
    if (sub != null) {
      try {
        await sub.cancel();
      } catch (_) {}
    }

    _stopPolling();

    final ctrl = _ctrl;
    _ctrl = null;
    if (ctrl != null && !ctrl.isClosed) {
      await ctrl.close();
    }
  }

  @override
  Stream<TelemetryState> watchState() {
    if (_disposed) return Stream<TelemetryState>.empty();
    return _ensureController().stream;
  }

  StreamController<TelemetryState> _ensureController() {
    final existing = _ctrl;
    if (existing != null && !existing.isClosed) return existing;

    final next = StreamController<TelemetryState>.broadcast();
    _ctrl = next;
    return next;
  }

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
      domain: _telemetryDomain,
      timeout: timeout,
      timeoutMessage: timeoutMessage,
    );
  }

  JsonRpcMeta _meta() => JsonRpcMeta(
        schema: _telemetrySchema,
        src: 'app',
        ts: DateTime.now().millisecondsSinceEpoch,
      );

  void _startPolling() {
    if (_pollTimer != null) return;
    if (pollInterval <= Duration.zero) return;

    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(_pollOnce());
    });

    unawaited(_pollOnce());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInFlight = false;
  }

  Future<void> _pollOnce() async {
    if (_disposed) return;
    if (_pollInFlight) return;
    if (!_jrpc.isConnected) return;

    _pollInFlight = true;
    try {
      final resp = await _request(
        method: _telemetryMethodGet,
        reqId: newReqId(),
        data: null,
        timeoutMessage: 'Timeout waiting for telemetry get response',
      );

      final data = resp.data;
      if (data == null) return;
      if (resp.meta != null && resp.meta!.schema != _telemetrySchema) {
        return;
      }

      final parsed = TelemetryState.fromJson(data);
      if (parsed == null) return;

      _emitState(parsed);
    } catch (_) {
      // Polling is best-effort; ignore errors/timeouts.
    } finally {
      _pollInFlight = false;
    }
  }

  void _emitState(
    TelemetryState next, {
    StreamController<TelemetryState>? ctrl,
  }) {
    _telemetry = next;
    final target = ctrl ?? _ctrl;
    if (target != null && !target.isClosed) {
      target.add(next);
    }
  }
}
