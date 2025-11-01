import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

/// In-memory mock of ScheduleRepository for local dev/tests.
/// Plug it instead of ScheduleRepositoryMqtt in DI for the "dev" flavor.
class ScheduleRepositoryMock implements ScheduleRepository {
  /// Artificial network-like delay for fetch/save operations.
  final Duration delay;

  /// Probability [0..1] to throw an artificial error on each operation.
  final double failureRate;

  final Random _rng;
  final Map<String, CalendarSnapshot> _db = {};
  final _changed = StreamController<String>.broadcast();

  ScheduleRepositoryMock({
    this.delay = const Duration(milliseconds: 250),
    this.failureRate = 0.0,
    Map<String, CalendarSnapshot>? seed,
    Random? rng,
  }) : _rng = rng ?? Random() {
    if (seed != null) {
      // Normalize all seeded snapshots for stable behavior.
      for (final e in seed.entries) {
        _db[e.key] = _normalize(e.value);
      }
    }
  }

  /// Optional: listen to deviceId when snapshot changes.
  Stream<String> get onChanged => _changed.stream;

  /// Convenience factory with a readable demo schedule.
  factory ScheduleRepositoryMock.demo({
    Duration delay = const Duration(milliseconds: 200),
  }) {
    return ScheduleRepositoryMock(
      delay: delay,
      seed: {
        // Example device preloaded with a weekly program.
        'dev-thermo-001': _normalize(_demoSnapshot()),
      },
    );
  }

  @override
  Future<CalendarSnapshot> fetchAll(String deviceId) async {
    await _maybeDelayAndFail('fetchAll($deviceId)');
    return _db.putIfAbsent(deviceId, () => _normalize(_defaultEmptySnapshot()));
  }

  @override
  Future<void> saveAll(String deviceId, CalendarSnapshot snapshot) async {
    await _maybeDelayAndFail('saveAll($deviceId)');
    _db[deviceId] = _normalize(snapshot);
    _changed.add(deviceId);
  }

  // --------------------- Helpers ---------------------

  Future<void> _maybeDelayAndFail(String op) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (failureRate > 0 && _rng.nextDouble() < failureRate) {
      throw Exception('Mock error in $op');
    }
  }

  static CalendarSnapshot _defaultEmptySnapshot() {
    return CalendarSnapshot(mode: CalendarMode.off, lists: {
      CalendarMode.manual: const <SchedulePoint>[],
      CalendarMode.antifreeze: const <SchedulePoint>[],
      CalendarMode.daily: const <SchedulePoint>[],
      CalendarMode.weekly: const <SchedulePoint>[],
    });
  }

  static CalendarSnapshot _demoSnapshot() {
    // Typical heating program example for weekly mode:
    // Weekdays: 06:30 21.0, 09:00 19.0, 17:30 21.0, 23:00 18.5
    // Weekend:  08:30 21.0, 23:30 18.5
    const wd = WeekdayMask.mon | WeekdayMask.tue | WeekdayMask.wed | WeekdayMask.thu | WeekdayMask.fri;
    const we = WeekdayMask.sat | WeekdayMask.sun;

    List<SchedulePoint> weekly = [
      SchedulePoint(time: const TimeOfDay(hour: 6, minute: 30), daysMask: wd, min: 21.0, max: 21.0),
      SchedulePoint(time: const TimeOfDay(hour: 9, minute: 0), daysMask: wd, min: 19.0, max: 19.0),
      SchedulePoint(time: const TimeOfDay(hour: 17, minute: 30), daysMask: wd, min: 21.0, max: 21.0),
      SchedulePoint(time: const TimeOfDay(hour: 23, minute: 0), daysMask: wd, min: 18.5, max: 18.5),
      SchedulePoint(time: const TimeOfDay(hour: 8, minute: 30), daysMask: we, min: 21.0, max: 21.0),
      SchedulePoint(time: const TimeOfDay(hour: 23, minute: 30), daysMask: we, min: 18.5, max: 18.5),
    ];

    return CalendarSnapshot(mode: CalendarMode.weekly, lists: {
      CalendarMode.manual: const <SchedulePoint>[],
      CalendarMode.antifreeze: const <SchedulePoint>[],
      CalendarMode.daily: const <SchedulePoint>[],
      CalendarMode.weekly: weekly,
    });
  }

  /// Normalize snapshot to match the same rules as the MQTT repo:
  /// - Ensure all modes exist
  /// - Clamp time and daysMask
  /// - Ensure min<=max and 0.1 resolution
  /// - Deduplicate (last wins) and sort by time then mask
  static CalendarSnapshot _normalize(CalendarSnapshot src) {
    final lists = Map<CalendarMode, List<SchedulePoint>>.from(src.lists);

    void ensure(CalendarMode m) => lists.putIfAbsent(m, () => <SchedulePoint>[]);
    ensure(CalendarMode.manual);
    ensure(CalendarMode.antifreeze);
    ensure(CalendarMode.daily);
    ensure(CalendarMode.weekly);

    Map<CalendarMode, List<SchedulePoint>> out = {};
    for (final e in lists.entries) {
      out[e.key] = _sortedDedup(e.value.map(_fixPoint).toList());
    }

    // Fallback mode if something weird is passed in.
    final mode = CalendarMode.all.firstWhere(
      (m) => m.id == src.mode.id,
      orElse: () => CalendarMode.off,
    );

    return CalendarSnapshot(mode: mode, lists: out);
  }

  static SchedulePoint _fixPoint(SchedulePoint p) {
    final hh = p.time.hour.clamp(0, 23);
    final mm = p.time.minute.clamp(0, 59);
    final mask = p.daysMask & WeekdayMask.all;

    final a = p.min;
    final b = p.max;
    final lo = a <= b ? a : b;
    final hi = b >= a ? b : a;

    double r1(double v) => double.parse(v.toStringAsFixed(1));

    return SchedulePoint(
      time: TimeOfDay(hour: hh, minute: mm),
      daysMask: mask,
      min: r1(lo),
      max: r1(hi),
    );
  }

  static List<SchedulePoint> _sortedDedup(List<SchedulePoint> pts) {
    final map = <String, SchedulePoint>{};
    for (final p in pts) {
      final key = '${p.daysMask}:${p.time.hour}:${p.time.minute}';
      map[key] = p; // last wins
    }
    final out = map.values.toList()
      ..sort((a, b) {
        final ai = _pMinutes(a.time);
        final bi = _pMinutes(b.time);
        if (ai != bi) return ai.compareTo(bi);
        return a.daysMask.compareTo(b.daysMask);
      });
    return out;
  }

  static int _pMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
}
