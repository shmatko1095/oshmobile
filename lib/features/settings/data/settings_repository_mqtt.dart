import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/stream_waiters.dart';
import 'package:oshmobile/features/settings/data/settings_topics.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryMqtt implements SettingsRepository {
  final DeviceMqttRepo _mqtt;
  final SettingsTopics _topics;
  final Duration timeout;

  // Snapshot watchers (UI).
  final Map<String, StreamController<MapEntry<String?, SettingsSnapshot>>> _ctrls = {};
  final Map<String, int> _refs = {};

  // Raw reported events for ACK waiting (no re-subscribe per operation).
  final Map<String, StreamController<MapEntry<int, dynamic>>> _rawCtrls = {};
  final Map<String, int> _seq = {};

  // One MQTT subscription per device (shared by snapshot watchers and ACK waiters).
  final Map<String, StreamSubscription> _subs = {};

  // Last known snapshot per device to support partial merge.
  final Map<String, SettingsSnapshot> _last = {};

  bool _disposed = false;

  SettingsRepositoryMqtt(
    this._mqtt,
    this._topics, {
    this.timeout = const Duration(seconds: 6),
  });

  /// Best-effort cleanup when session scope is disposed.
  /// Not part of SettingsRepository interface on purpose.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_disposeAsync());
  }

  Future<void> _disposeAsync() async {
    final subs = _subs.values.toList(growable: false);
    final ctrls = _ctrls.values.toList(growable: false);
    final rawCtrls = _rawCtrls.values.toList(growable: false);

    _subs.clear();
    _ctrls.clear();
    _rawCtrls.clear();
    _refs.clear();
    _seq.clear();
    _last.clear();

    for (final s in subs) {
      try {
        await s.cancel();
      } catch (_) {}
    }
    for (final c in ctrls) {
      try {
        if (!c.isClosed) await c.close();
      } catch (_) {}
    }
    for (final c in rawCtrls) {
      try {
        if (!c.isClosed) await c.close();
      } catch (_) {}
    }
  }

  // -------------------- Public API --------------------

  @override
  Future<SettingsSnapshot> fetchAll(String deviceSn) async {
    if (_disposed) throw StateError('SettingsRepositoryMqtt is disposed');

    final getTopic = _topics.getReq(deviceSn);

    _ensureReportedSubscription(deviceSn);
    final events = _reportedEvents(deviceSn);

    // Cursor to avoid consuming older reported messages.
    final startSeq = _seq[deviceSn] ?? 0;

    // Attach waiter before publish to avoid race with fast device responses.
    final waitNext = firstWhereWithTimeout<MapEntry<int, dynamic>>(
      events,
      (e) => e.key > startSeq,
      timeout,
      timeoutMessage: 'Timeout waiting for first settings reported',
    );

    final reqId = newReqId();
    unawaited(_mqtt.publishJson(getTopic, {'reqId': reqId}));

    final ev = await waitNext;

    final map = decodeMqttMap(ev.value);
    final snap = _mergePartial(deviceSn, map);
    _last[deviceSn] = snap;
    return snap;
  }

  @override
  Future<void> saveAll(
    String deviceSn,
    SettingsSnapshot snapshot, {
    String? reqId,
  }) async {
    if (_disposed) throw StateError('SettingsRepositoryMqtt is disposed');

    final desiredTopic = _topics.desired(deviceSn);
    final id = reqId ?? newReqId();

    _ensureReportedSubscription(deviceSn);
    final events = _reportedEvents(deviceSn);

    // Full snapshot payload.
    final payload = <String, dynamic>{
      'reqId': id,
      ...snapshot.toJson(),
    };

    // Cursor to avoid consuming older reported messages.
    final startSeq = _seq[deviceSn] ?? 0;

    // Prefer correlation by reqId; otherwise accept "next reported" (legacy behavior).
    final ackWait = firstWhereWithTimeout<MapEntry<int, dynamic>>(
      events,
      (e) => e.key > startSeq && matchesReqId(e.value, id),
      timeout,
      timeoutMessage: 'Timeout waiting for settings ACK',
    );

    await _mqtt.publishJson(desiredTopic, payload);

    try {
      await ackWait;
    } on TimeoutException {
      await firstWhereWithTimeout<MapEntry<int, dynamic>>(
        events,
        (e) => e.key > startSeq,
        timeout,
        timeoutMessage: 'Timeout waiting for settings reported after publish',
      );
    }
  }

  @override
  Stream<MapEntry<String?, SettingsSnapshot>> watchSnapshot(String deviceSn) {
    if (_disposed) return Stream<MapEntry<String?, SettingsSnapshot>>.empty();

    final existing = _ctrls[deviceSn];
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    late final StreamController<MapEntry<String?, SettingsSnapshot>> ctrl;

    ctrl = StreamController<MapEntry<String?, SettingsSnapshot>>.broadcast(
      onListen: () async {
        _refs[deviceSn] = (_refs[deviceSn] ?? 0) + 1;

        // Already active listeners for the same device; just increase ref-count.
        if (_refs[deviceSn]! > 1) return;

        final getTopic = _topics.getReq(deviceSn);

        // Ensure shared subscription is active.
        _ensureReportedSubscription(deviceSn);

        // Request retained snapshot right away.
        unawaited(_mqtt.publishJson(getTopic, {'reqId': newReqId()}));
      },
      onCancel: () async {
        _refs[deviceSn] = (_refs[deviceSn] ?? 1) - 1;
        if (_refs[deviceSn]! <= 0) {
          _refs.remove(deviceSn);

          // Do NOT cancel MQTT subscription here: it is shared with ACK waiters.
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

  // -------------------- Shared subscription + raw events --------------------

  /// Ensures there is exactly one MQTT subscription to the reported topic per device.
  /// The subscription is shared and stays alive until repository dispose().
  void _ensureReportedSubscription(String deviceSn) {
    if (_subs.containsKey(deviceSn)) return;

    final reportedTopic = _topics.reported(deviceSn);

    _subs[deviceSn] = _mqtt.subscribeJson(reportedTopic).listen((msg) {
      final nextSeq = (_seq[deviceSn] ?? 0) + 1;
      _seq[deviceSn] = nextSeq;

      // 1) Fan-out raw payload for ACK waiting.
      final rawCtrl = _rawCtrls[deviceSn];
      if (rawCtrl != null && !rawCtrl.isClosed) {
        rawCtrl.add(MapEntry(nextSeq, msg.payload));
      }

      // 2) Decode + merge to snapshot stream (for UI watchers).
      final map = decodeMqttMap(msg.payload);
      final applied = extractReqIdFromMap(map);
      final snap = _mergePartial(deviceSn, map);

      _last[deviceSn] = snap;

      final snapCtrl = _ctrls[deviceSn];
      if (snapCtrl != null && !snapCtrl.isClosed) {
        snapCtrl.add(MapEntry(applied, snap));
      }
    });
  }

  /// Returns a broadcast stream of raw reported payloads with monotonic sequence numbers.
  /// Sequence numbers allow "wait for next" semantics without re-subscribing.
  Stream<MapEntry<int, dynamic>> _reportedEvents(String deviceSn) {
    final existing = _rawCtrls[deviceSn];
    if (existing != null && !existing.isClosed) return existing.stream;

    final ctrl = StreamController<MapEntry<int, dynamic>>.broadcast(
      onListen: () {
        _ensureReportedSubscription(deviceSn);
      },
    );

    _rawCtrls[deviceSn] = ctrl;
    return ctrl.stream;
  }

  /// Merge a partial reported map into last known snapshot for [deviceSn].
  /// For simplicity: deep-merge on top of the previous snapshot.
  SettingsSnapshot _mergePartial(String deviceSn, Map<String, dynamic> map) {
    final prev = _last[deviceSn] ?? SettingsSnapshot.empty();
    return prev.merged(map);
  }
}
