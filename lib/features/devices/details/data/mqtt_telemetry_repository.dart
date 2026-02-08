import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_topics.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';

/// Telemetry repo on top of DeviceMqttRepo (JSON-only).
/// Produces alias-keyed maps like {"state": {...}} or {"temp": 21.5}
class MqttTelemetryRepositoryImpl implements TelemetryRepository {
  MqttTelemetryRepositoryImpl({
    required DeviceMqttRepo mqtt,
    required TelemetryTopics topics,
    required String deviceSn,
  })  : _mqtt = mqtt,
        _topics = topics,
        _deviceSn = deviceSn;

  final DeviceMqttRepo _mqtt;
  final TelemetryTopics _topics;
  final String _deviceSn;

  StreamController<Map<String, dynamic>>? _ctrl;
  List<StreamSubscription> _subs = [];
  int _refs = 0;

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
  Future<void> subscribe() async {
    if (_disposed) return;

    _refs += 1;
    if (_refs > 1) return;

    final ctrl = _ensureController();
    final subs = <StreamSubscription>[];

    // 1) device state
    subs.add(
      _mqtt.subscribeJson(_topics.state(_deviceSn)).listen((msg) {
        ctrl.add({'state': msg.payload});
      }),
    );

    // 2) device telemetry/*
    subs.add(
      _mqtt.subscribeJson(_topics.telemetryAll(_deviceSn)).listen((msg) {
        final alias = _extractAliasAfter(msg.topic, 'telemetry') ?? 'telemetry';
        ctrl.add({alias: msg.payload});
      }),
    );

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

  // -------- helpers --------

  /// Extract alias: finds `needle` segment in topic and returns the next segment.
  String? _extractAliasAfter(String topic, String needle) {
    final parts = topic.split('/');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] == needle && i + 1 < parts.length) {
        final next = parts[i + 1];
        if (next.isNotEmpty && next != '#') return next;
      }
    }
    return null;
  }
}
