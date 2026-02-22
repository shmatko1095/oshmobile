import 'dart:async';

import 'package:oshmobile/core/contracts/osh_contracts.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc_client.dart';
import 'package:oshmobile/core/network/mqtt/json_rpc.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_topics.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';
import 'package:oshmobile/features/sensors/data/sensors_jsonrpc_codec.dart';

class TelemetryJsonRpcCodec {
  static final _contract = OshContracts.current.telemetry;

  static String get schema => _contract.schema;
  static String get domain => _contract.methodDomain;

  static String methodOf(String op) => _contract.method(op);

  static String get methodState => methodOf('state');
  static String get methodGet => methodOf('get');
  static String get methodSet => methodOf('set');
  static String get methodPatch => methodOf('patch');
}

/// Telemetry repo on top of DeviceMqttRepo (JSON-RPC).
/// Produces alias-keyed diffs, e.g. {'sensor.temperature': 21.5}.
class MqttTelemetryRepositoryImpl implements TelemetryRepository {
  MqttTelemetryRepositoryImpl({
    required JsonRpcClient jrpc,
    required TelemetryTopics topics,
    required String deviceSn,
    this.pollInterval = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 6),
  })  : _jrpc = jrpc,
        _topics = topics,
        _deviceSn = deviceSn;

  final JsonRpcClient _jrpc;
  final TelemetryTopics _topics;
  final String _deviceSn;
  final Duration pollInterval;
  final Duration timeout;

  StreamController<Map<String, dynamic>>? _ctrl;
  List<StreamSubscription> _subs = [];
  int _refs = 0;

  Timer? _pollTimer;
  bool _pollInFlight = false;

  SensorsState? _sensors;
  TelemetryState? _telemetry;
  Map<String, dynamic> _lastAliases = {};

  bool _disposed = false;

  /// Best-effort cleanup when device scope is disposed.
  /// Not part of TelemetryRepository interface on purpose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final subs = _subs.toList(growable: false);
    _subs = [];

    final ctrl = _ctrl;
    _ctrl = null;
    _refs = 0;

    _pollTimer?.cancel();
    _pollTimer = null;
    _pollInFlight = false;

    _sensors = null;
    _telemetry = null;
    _lastAliases = {};

    for (final s in subs) {
      try {
        await s.cancel();
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
      method: TelemetryJsonRpcCodec.methodGet,
      reqId: reqId,
      data: null,
      timeoutMessage: 'Timeout waiting for telemetry get response',
    );

    final data = resp.data;
    if (data == null) throw StateError('Invalid telemetry response');
    if (resp.meta != null &&
        resp.meta!.schema != TelemetryJsonRpcCodec.schema) {
      throw StateError('Invalid telemetry schema: ${resp.meta!.schema}');
    }

    final parsed = TelemetryState.fromJson(data);
    if (parsed == null) throw StateError('Invalid telemetry payload');

    _telemetry = parsed;
    _emitAliases();
    return parsed;
  }

  @override
  Future<void> set({String? reqId}) async {
    if (_disposed) throw StateError('MqttTelemetryRepositoryImpl is disposed');
    final id = reqId ?? newReqId();
    await _request(
      method: TelemetryJsonRpcCodec.methodSet,
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
      method: TelemetryJsonRpcCodec.methodPatch,
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
    final subs = <StreamSubscription>[];

    subs.add(
      _jrpc
          .notifications(
        _topics.stateSensors(_deviceSn),
        method: SensorsJsonRpcCodec.methodState,
        schema: SensorsJsonRpcCodec.schema,
      )
          .listen((notif) {
        final data = notif.data;
        if (data == null) return;

        final parsed = SensorsState.fromJson(data);
        if (parsed == null) return;

        _sensors = parsed;
        _emitAliases(ctrl: ctrl);
      }),
    );

    subs.add(
      _jrpc
          .notifications(
        _topics.stateTelemetry(_deviceSn),
        method: TelemetryJsonRpcCodec.methodState,
        schema: TelemetryJsonRpcCodec.schema,
      )
          .listen((notif) {
        final data = notif.data;
        if (data == null) return;

        final parsed = TelemetryState.fromJson(data);
        if (parsed == null) return;

        _telemetry = parsed;
        _emitAliases(ctrl: ctrl);
      }),
    );

    _startPolling();

    _subs = subs;
  }

  @override
  Future<void> unsubscribe() async {
    if (_disposed) return;

    _refs -= 1;
    if (_refs > 0) return;

    _refs = 0;

    for (final s in _subs) {
      try {
        await s.cancel();
      } catch (_) {}
    }
    _subs = [];

    _stopPolling();

    final ctrl = _ctrl;
    _ctrl = null;
    if (ctrl != null && !ctrl.isClosed) {
      await ctrl.close();
    }
  }

  @override
  Stream<Map<String, dynamic>> watchAliases() {
    if (_disposed) return Stream<Map<String, dynamic>>.empty();
    return _ensureController().stream;
  }

  StreamController<Map<String, dynamic>> _ensureController() {
    final existing = _ctrl;
    if (existing != null && !existing.isClosed) return existing;

    final next = StreamController<Map<String, dynamic>>.broadcast();
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
      domain: TelemetryJsonRpcCodec.domain,
      timeout: timeout,
      timeoutMessage: timeoutMessage,
    );
  }

  JsonRpcMeta _meta() => JsonRpcMeta(
        schema: TelemetryJsonRpcCodec.schema,
        src: 'app',
        ts: DateTime.now().millisecondsSinceEpoch,
      );

  void _startPolling() {
    if (_pollTimer != null) return;
    if (pollInterval <= Duration.zero) return;

    _pollTimer = Timer.periodic(pollInterval, (_) {
      unawaited(_pollOnce());
    });

    // Trigger an immediate poll to avoid waiting for the first tick.
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
        method: TelemetryJsonRpcCodec.methodGet,
        reqId: newReqId(),
        data: null,
        timeoutMessage: 'Timeout waiting for telemetry get response',
      );

      final data = resp.data;
      if (data == null) return;
      if (resp.meta != null &&
          resp.meta!.schema != TelemetryJsonRpcCodec.schema) return;

      final parsed = TelemetryState.fromJson(data);
      if (parsed == null) return;

      _telemetry = parsed;
      _emitAliases();
    } catch (_) {
      // Polling is best-effort; ignore errors/timeouts.
    } finally {
      _pollInFlight = false;
    }
  }

  void _emitAliases({StreamController<Map<String, dynamic>>? ctrl}) {
    final next = _buildAliases();
    final diff = _diffAliases(_lastAliases, next);
    if (diff.isEmpty) return;

    _lastAliases = next;

    final target = ctrl ?? _ctrl;
    if (target != null && !target.isClosed) {
      target.add(diff);
    }
  }

  Map<String, dynamic> _buildAliases() {
    final out = <String, dynamic>{};

    final telemetry = _telemetry;
    out['switch.heating.state'] = telemetry?.heaterEnabled;
    out['stats.heating_duty_24h'] = telemetry?.loadFactor;

    final refMeta = _sensors?.items.firstWhere(
      (e) => e.ref,
      orElse: () => const SensorMeta(
        id: '',
        name: '',
        ref: false,
        transport: '',
        removable: false,
        kind: 'generic',
        tempCalibration: 0.0,
      ),
    );

    ClimateSensorTelemetry? refTelemetry;
    if (telemetry != null && refMeta != null && refMeta.id.isNotEmpty) {
      for (final item in telemetry.climateSensors) {
        if (item.id == refMeta.id) {
          refTelemetry = item;
          break;
        }
      }
    }

    out['sensor.temperature'] = (refTelemetry != null && refTelemetry.tempValid)
        ? refTelemetry.temp
        : null;
    out['sensor.humidity'] =
        (refTelemetry != null && refTelemetry.humidityValid)
            ? refTelemetry.humidity
            : null;

    return out;
  }

  Map<String, dynamic> _diffAliases(
      Map<String, dynamic> prev, Map<String, dynamic> next) {
    final diff = <String, dynamic>{};
    final keys = <String>{}
      ..addAll(prev.keys)
      ..addAll(next.keys);
    for (final key in keys) {
      final prevVal = prev[key];
      final hasNext = next.containsKey(key);
      final nextVal = hasNext ? next[key] : null;
      if (prevVal != nextVal) {
        diff[key] = nextVal;
      }
    }
    return diff;
  }
}
