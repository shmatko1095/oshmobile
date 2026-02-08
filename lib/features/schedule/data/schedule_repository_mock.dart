import 'dart:async';

import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryMock implements ScheduleRepository {
  CalendarSnapshot? _snap;
  final StreamController<CalendarSnapshot> _watcher = StreamController<CalendarSnapshot>.broadcast();

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

  CalendarSnapshot _current() => _snap ??= _empty();

  @override
  Future<CalendarSnapshot> fetchAll({bool forceGet = false}) async {
    await _delay();
    return _current();
  }

  @override
  Future<void> saveAll(CalendarSnapshot snapshot, {String? reqId}) async {
    await _delay();
    _snap = snapshot;
    _emit(snapshot);
  }

  @override
  Stream<CalendarSnapshot> watchSnapshot() {
    // Emit retained
    scheduleMicrotask(() => _emit(_current()));
    return _watcher.stream;
  }

  @override
  Future<void> setMode(CalendarMode mode, {String? reqId}) async {
    await _delay();
    final next = _current().copyWith(mode: mode);
    _snap = next;
    _emit(next);
  }

  void _emit(CalendarSnapshot snap) {
    if (!_watcher.isClosed) {
      _watcher.add(snap);
    }
  }
}
