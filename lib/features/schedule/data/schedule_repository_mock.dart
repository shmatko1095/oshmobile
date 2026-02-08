import 'dart:async';

import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryMock implements ScheduleRepository {
  final Map<String, CalendarSnapshot> _db = {};
  final Map<String, StreamController<CalendarSnapshot>> _watchers = {};

  Future<void> _delay() async => Future<void>.delayed(const Duration(milliseconds: 150));

  CalendarSnapshot _empty() => CalendarSnapshot(
        mode: CalendarMode.off,
        lists: {
          CalendarMode.off: const [],
          CalendarMode.on: const [],
          CalendarMode.antifreeze: const [],
          CalendarMode.daily: const [],
          CalendarMode.weekly: const [],
        },
      );

  @override
  Future<CalendarSnapshot> fetchAll(String deviceSn, {bool forceGet = false}) async {
    await _delay();
    return _db[deviceSn] ?? _empty();
  }

  @override
  Future<void> saveAll(String deviceSn, CalendarSnapshot snapshot, {String? reqId}) async {
    await _delay();
    _db[deviceSn] = snapshot;
    _emit(deviceSn, snapshot);
  }

  @override
  Stream<CalendarSnapshot> watchSnapshot(String deviceSn) {
    final c = _watchers.putIfAbsent(deviceSn, () => StreamController<CalendarSnapshot>.broadcast());
    // Emit retained
    scheduleMicrotask(() => _emit(deviceSn, _db[deviceSn] ?? _empty()));
    return c.stream;
  }

  @override
  Future<void> setMode(String deviceSn, CalendarMode mode, {String? reqId}) async {
    await _delay();
    final cur = _db[deviceSn] ?? _empty();
    final next = cur.copyWith(mode: mode);
    _db[deviceSn] = next;
    _emit(deviceSn, next);
  }

  void _emit(String deviceSn, CalendarSnapshot snap) {
    final c = _watchers[deviceSn];
    if (c != null && !c.isClosed) {
      c.add(snap);
    }
  }
}
