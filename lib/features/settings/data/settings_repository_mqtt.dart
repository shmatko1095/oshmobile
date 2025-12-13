import 'dart:async';
import 'dart:convert';

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

  final Map<String, StreamController<MapEntry<String?, SettingsSnapshot>>> _ctrls = {};
  final Map<String, StreamSubscription> _subs = {};
  final Map<String, int> _refs = {};
  final Map<String, SettingsSnapshot> _last = {};

  bool _disposed = false;

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

    _subs.clear();
    _ctrls.clear();
    _refs.clear();
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
  }

  // Stream waiting helpers live in core/utils/stream_waiters.dart.


  SettingsRepositoryMqtt(
    this._mqtt,
    this._topics, {
    this.timeout = const Duration(seconds: 6),
  });

  @override
  Future<SettingsSnapshot> fetchAll(String deviceSn) async {
    if (_disposed) throw StateError('SettingsRepositoryMqtt is disposed');

    final reportedTopic = _topics.reported(deviceSn);
    final getTopic = _topics.getReq(deviceSn);

    final stream = _mqtt.subscribeJson(reportedTopic);

    final reqId = newReqId();
    unawaited(_mqtt.publishJson(getTopic, {'reqId': reqId}));

    final msg = await firstWithTimeout(
      stream,
      timeout,
      timeoutMessage: 'Timeout waiting for first settings reported',
    );
    final map = _decodeMap(msg.payload);
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

    final reportedTopic = _topics.reported(deviceSn);
    final desiredTopic = _topics.desired(deviceSn);

    final id = reqId ?? newReqId();

    // Полный снапшот.
    final payload = <String, dynamic>{
      'reqId': id,
      ...snapshot.toJson(),
    };

    final repStream = _mqtt.subscribeJson(reportedTopic);
    await _mqtt.publishJson(desiredTopic, payload);

    // Предпочитаем корреляцию по reqId; иначе берём первый reported.
    try {
      await firstWhereWithTimeout<dynamic>(
        repStream.map((e) => e.payload),
        (p) => _matchesReqId(p, id),
        timeout,
        timeoutMessage: 'Timeout waiting for settings ACK',
      );
    } on TimeoutException {
      await firstWithTimeout(
        repStream,
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
        // Уже есть активный listener и subscription – просто увеличиваем ref-count.
        if (_refs[deviceSn]! > 1) return;

        final reportedTopic = _topics.reported(deviceSn);
        final getTopic = _topics.getReq(deviceSn);

        _subs[deviceSn] = _mqtt.subscribeJson(reportedTopic).listen((msg) {
          final map = _decodeMap(msg.payload);
          final applied = _extractAppliedReqId(map);
          final snap = _mergePartial(deviceSn, map);

          _last[deviceSn] = snap;
          if (!ctrl.isClosed) {
            ctrl.add(MapEntry(applied, snap));
          }
        });

        // Сразу просим ретейн-снапшот.
        unawaited(_mqtt.publishJson(getTopic, {'reqId': newReqId()}));
      },
      onCancel: () async {
        _refs[deviceSn] = (_refs[deviceSn] ?? 1) - 1;
        if (_refs[deviceSn]! <= 0) {
          _refs.remove(deviceSn);
          await _subs.remove(deviceSn)?.cancel();
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

  // ------------ Helpers ------------

  Map<String, dynamic> _decodeMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    if (raw is String && raw.isNotEmpty) {
      try {
        return (jsonDecode(raw) as Map).cast<String, dynamic>();
      } catch (_) {
        return const <String, dynamic>{};
      }
    }
    return const <String, dynamic>{};
  }

  /// Try to extract applied reqId from reported payload.
  ///
  /// Supported shapes:
  /// - { "meta": { "lastAppliedSettingsReqId": "123" } }
  /// - { "meta": { "lastAppliedReqId": "123" } }
  /// - { "reqId": "123" }
  /// - { "data": { "reqId": "123" } }
  String? _extractAppliedReqId(Map<String, dynamic> map) {
    final meta = map['meta'];
    if (meta is Map) {
      final mm = meta.cast<String, dynamic>();
      final v = mm['lastAppliedSettingsReqId'] ?? mm['lastAppliedReqId'];
      if (v != null) return v.toString();
    }

    final v = map['reqId'];
    if (v != null) return v.toString();

    final data = map['data'];
    if (data is Map && data['reqId'] != null) {
      return data['reqId'].toString();
    }

    return null;
  }

  /// Merge a partial reported map into last known snapshot for [deviceSn].
  ///
  /// Для простоты: просто deep-merge поверх прошлого снапшота.
  SettingsSnapshot _mergePartial(String deviceSn, Map<String, dynamic> map) {
    final prev = _last[deviceSn] ?? SettingsSnapshot.empty();
    return prev.merged(map);
  }

  bool _matchesReqId(dynamic payload, String expected) {
    if (payload == null) return false;
    if (payload is String) return payload == expected;
    if (payload is Map && payload['reqId']?.toString() == expected) return true;

    final meta = (payload is Map) ? payload['meta'] : null;
    if (meta is Map &&
        (meta['lastAppliedSettingsReqId']?.toString() == expected ||
            meta['lastAppliedReqId']?.toString() == expected)) {
      return true;
    }

    final data = (payload is Map) ? payload['data'] : null;
    if (data is Map && data['reqId']?.toString() == expected) return true;

    return false;
  }
}
