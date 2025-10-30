import 'dart:async';

import 'package:oshmobile/core/network/mqtt/device_mqtt_repo.dart';
import 'package:oshmobile/features/schedule/data/schedule_repository.dart';

import '../domain/models/schedule_models.dart';
import 'schedule_topics.dart';

/// MQTT-backed ScheduleRepository.
/// Encapsulates protocol mechanics: retained reported snapshot, get request,
/// desired update with optional ACK via reported.
class MqttScheduleRepository implements ScheduleRepository {
  MqttScheduleRepository({
    required this.mqtt,
    required this.topics,
    this.snapshotTimeout = const Duration(seconds: 5),
    this.ackTimeout = const Duration(seconds: 5),
    this.waitAck = true,
  });

  final DeviceMqttRepo mqtt;
  final ScheduleTopics topics;
  final Duration snapshotTimeout; // how long we wait for reported snapshot
  final Duration ackTimeout; // how long we wait for ACK after save
  final bool waitAck; // whether save waits for reported echo

  @override
  Future<List<SchedulePoint>> fetchSchedule(String deviceId, CalendarMode mode) async {
    // 1) Listen to retained reported (first event should arrive immediately if retained is present)
    final Stream<MqttJson> reported = mqtt.subscribeJson(topics.reported(deviceId)).asBroadcastStream();

    // 2) Proactively ask device to publish a fresh snapshot (covers the case when retained is missing/stale)
    unawaited(mqtt.publishJson(topics.getReq(deviceId), {
      'mode': mode.name,
      'ts': DateTime.now().toUtc().toIso8601String(),
    }));

    // 3) Take the first valid snapshot for requested mode
    final msg = await reported.first.timeout(snapshotTimeout);
    return _parsePoints(msg.payload, mode);
  }

  @override
  Future<void> saveSchedule(String deviceId, CalendarMode mode, List<SchedulePoint> points) async {
    final corrId = DateTime.now().microsecondsSinceEpoch.toString();

    // 1) Publish desired changes (full replace). If you use patch on FW, include only diffs.
    await mqtt.publishJson(topics.desired(deviceId), {
      'mode': mode.name,
      'points': points.map((p) => p.toJson()).toList(),
      'corrId': corrId, // preferred ACK correlation
      'ts': DateTime.now().toUtc().toIso8601String(),
    });

    if (!waitAck) return;

    // 2) Await ACK through reported echo (corrId mirror or data match heuristic)
    final Stream<MqttJson> reported = mqtt.subscribeJson(topics.reported(deviceId));
    await reported.firstWhere((m) => _looksApplied(m.payload, mode, points, corrId)).timeout(ackTimeout, onTimeout: () {
      throw TimeoutException('No reported ACK within ${ackTimeout.inSeconds}s');
    });
  }

  // -------------------- helpers --------------------

  List<SchedulePoint> _parsePoints(Map<String, dynamic> json, CalendarMode mode) {
    // Expected shape: { daily: [...], weekly: [...] }
    // Accepts also { points: [...] } if FW sends mode-specific payloads.
    final key = mode == CalendarMode.weekly ? 'weekly' : 'daily';
    final dynamic listRaw = json.containsKey(key) ? json[key] : json['points'];

    if (listRaw is! List) return const <SchedulePoint>[];

    final out = <SchedulePoint>[];
    for (final e in listRaw) {
      if (e is Map) {
        try {
          out.add(SchedulePoint.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {}
      }
    }

    // Dedup by (daysMask, time) and sort by time
    return _sortedDedup(out);
  }

  bool _looksApplied(
    Map<String, dynamic> json,
    CalendarMode mode,
    List<SchedulePoint> want,
    String corrId,
  ) {
    // Preferred: device mirrors corrId in reported after applying desired
    if (json['corrId'] == corrId) return true;

    // Fallback: compare last point (cheap heuristic)
    final have = _parsePoints(json, mode);
    if (want.isEmpty || have.isEmpty) return false;
    final a = have.last, b = want.last;
    return a.daysMask == b.daysMask &&
        a.time.hour == b.time.hour &&
        a.time.minute == b.time.minute &&
        (a.temperature - b.temperature).abs() < 0.01;
  }

  List<SchedulePoint> _sortedDedup(List<SchedulePoint> pts) {
    final byKey = <String, SchedulePoint>{};
    for (final p in pts) {
      final k = '${p.daysMask}:${p.time.hour}:${p.time.minute}';
      byKey[k] = p; // last wins
    }
    final res = byKey.values.toList()
      ..sort((a, b) {
        final ai = a.time.hour * 60 + a.time.minute;
        final bi = b.time.hour * 60 + b.time.minute;
        return ai.compareTo(bi);
      });
    return res;
  }
}
