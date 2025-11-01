import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/features/devices/details/data/telemetry_topics.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';

/// Telemetry repo on top of DeviceMqttRepo (JSON-only).
/// Produces alias-keyed maps like {"state": {...}} or {"temp": 21.5}
class MqttTelemetryRepositoryImpl implements TelemetryRepository {
  MqttTelemetryRepositoryImpl(this._mqtt, this._topics);

  final DeviceMqttRepo _mqtt;
  final TelemetryTopics _topics;

  // per-device broadcast + refcount + underlying stream subs
  final Map<String, StreamController<Map<String, dynamic>>> _ctrls = {};
  final Map<String, int> _refs = {};
  final Map<String, List<StreamSubscription>> _subs = {};

  @override
  Future<void> subscribe(String deviceId) async {
    _refs[deviceId] = (_refs[deviceId] ?? 0) + 1;
    if (_refs[deviceId]! > 1) return; // already wired

    final ctrl = _ctrls.putIfAbsent(deviceId, () => StreamController<Map<String, dynamic>>.broadcast());

    final subs = <StreamSubscription>[];

    // 1) device state
    subs.add(
      _mqtt.subscribeJson(_topics.state(deviceId)).listen((msg) {
        ctrl.add({'state': msg.payload});
      }),
    );

    // 2) device telemetry/*
    subs.add(
      _mqtt.subscribeJson(_topics.telemetryAll(deviceId)).listen((msg) {
        final alias = _extractAliasAfter(msg.topic, 'telemetry') ?? 'telemetry';
        ctrl.add({alias: msg.payload});
      }),
    );

    // 3) optional service/device/telemetry/{deviceId}/*
    subs.add(
      _mqtt.subscribeJson(_topics.serviceAll(deviceId)).listen((msg) {
        final alias = _extractAliasAfter(msg.topic, deviceId) ?? 'telemetry';
        ctrl.add({alias: msg.payload});
      }),
    );

    _subs[deviceId] = subs;
  }

  @override
  Future<void> unsubscribe(String deviceId) async {
    final n = (_refs[deviceId] ?? 0) - 1;
    if (n <= 0) {
      _refs.remove(deviceId);
      // cancel subs
      for (final s in _subs.remove(deviceId) ?? const <StreamSubscription>[]) {
        await s.cancel();
      }
      // close controller
      await _ctrls.remove(deviceId)?.close();
    } else {
      _refs[deviceId] = n;
    }
  }

  @override
  Stream<Map<String, dynamic>> watchAliases(String deviceId) {
    return _ctrls.putIfAbsent(deviceId, () => StreamController<Map<String, dynamic>>.broadcast()).stream;
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
