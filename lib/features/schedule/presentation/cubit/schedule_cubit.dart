import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/usecases/fetch_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/save_schedule_all.dart';

part 'schedule_state.dart';

class DeviceScheduleCubit extends Cubit<DeviceScheduleState> {
  final FetchScheduleAll _fetchAll;
  final SaveScheduleAll _saveAll;

  DeviceScheduleCubit({
    required FetchScheduleAll fetchAll,
    required SaveScheduleAll saveAll,
  })  : _fetchAll = fetchAll,
        _saveAll = saveAll,
        super(const DeviceScheduleLoading());

  String _deviceSn = '';
  int _bindToken = 0;

  Future<void> rebind() async {
    await bind(_deviceSn);
  }

  // ---------------- Bind & load ----------------
  Future<void> bind(String deviceSn) async {
    _deviceSn = deviceSn;
    final token = ++_bindToken;
    emit(DeviceScheduleLoading());
    try {
      final snap = await _fetchAll(deviceSn);
      if (token != _bindToken) return;
      final safeMode = CalendarMode.all.any((m) => m.id == snap.mode.id) ? snap.mode : CalendarMode.off;
      emit(DeviceScheduleReady(snap: snap.copyWith(mode: safeMode)));
    } catch (e) {
      if (token != _bindToken) return;
      emit(DeviceScheduleError(e.toString()));
    }
  }

  // ---------------- Mode API ----------------
  CalendarMode getMode() => state.mode;

  /// Only switches active list. Does NOT transform data.
  void setMode(CalendarMode next) {
    final s = state;
    if (s is! DeviceScheduleReady) return;
    if (s.snap.mode.id == next.id) return;
    emit(s.copyWith(
      snap: s.snap.copyWith(mode: next),
      dirty: true,
      flash: null,
    ));
  }

  // ---------------- Mutations (active list only) ----------------

  // --- add to imports if needed ---
// no extra imports required

// ===================== NEW HELPERS =====================

  TimeOfDay _addMinutes(TimeOfDay t, int delta) {
    var total = (t.hour * 60 + t.minute + delta) % 1440;
    if (total < 0) total += 1440;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  bool _existsAt(List<SchedulePoint> pts, int daysMask, TimeOfDay t) {
    return pts.any((p) => p.daysMask == daysMask && p.time.hour == t.hour && p.time.minute == t.minute);
  }

  /// Finds the first free time >= start with a given step (minutes).
  TimeOfDay _nextFreeTime(
    List<SchedulePoint> pts,
    int daysMask,
    TimeOfDay start, {
    int stepMinutes = 15, // keep your 15-min grid by default
  }) {
    var t = start;
    for (int i = 0; i < 1440; i += stepMinutes) {
      if (!_existsAt(pts, daysMask, t)) return t;
      t = _addMinutes(t, stepMinutes);
    }
    // Shouldn't happen (only if all minutes of a day are taken).
    return start;
  }

// ===================== UPDATED addPoint =====================

  // Add a new point to the active mode.
// If [p] is null, the cubit creates a default point:
// - time: now rounded to 15 minutes (forward),
// - days: workdays for weekly mode, otherwise all days,
// - setpoint: 21.0°C (min == max).
// Time is auto-shifted to the nearest free minute to keep (daysMask, hh:mm) unique.
  void addPoint([SchedulePoint? p, int stepMinutes = 15]) {
    final s = state;
    if (s is! DeviceScheduleReady) return;

    final mode = s.snap.mode;
    final current = List<SchedulePoint>.from(s.snap.lists[mode] ?? const <SchedulePoint>[]);

    // --- defaults if no point passed in ---
    int daysMask;
    TimeOfDay t;
    double minV, maxV;

    if (p == null) {
      final now = TimeOfDay.now();
      final roundMin = ((now.minute + 14) ~/ 15) * 15;
      t = TimeOfDay(hour: (now.hour + (roundMin ~/ 60)) % 24, minute: roundMin % 60);

      daysMask = (mode.id == CalendarMode.weekly.id)
          ? (WeekdayMask.mon | WeekdayMask.tue | WeekdayMask.wed | WeekdayMask.thu | WeekdayMask.fri)
          : WeekdayMask.all;

      minV = 21.0;
      maxV = 21.0;
    } else {
      t = p.time;
      daysMask = p.daysMask;
      minV = p.min;
      maxV = p.max;
    }

    // normalize values (clamp, order min<=max, mask sanitize)
    var candidate = _norm(SchedulePoint(time: t, daysMask: daysMask, min: minV, max: maxV));

    // ensure unique time within (daysMask, hh:mm) in the current active list
    final freeTime = _nextFreeTime(current, candidate.daysMask, candidate.time, stepMinutes: stepMinutes);
    if (freeTime != candidate.time) {
      candidate = candidate.copyWith(time: freeTime);
    }

    // push via the common mutate pipeline (sort + dedup for safety)
    _mutateActive((list) => [...list, candidate]);
  }

  void changePoint(int index, SchedulePoint p) => _mutateActive((list) {
        if (index < 0 || index >= list.length) return list;
        final copy = [...list];
        copy[index] = _norm(p);
        return copy;
      });

  void removeAt(int index) => _mutateActive((list) {
        if (index < 0 || index >= list.length) return list;
        final copy = [...list]..removeAt(index);
        return copy;
      });

  void replaceAll(List<SchedulePoint> next) => _mutateActive((_) => next.map(_norm).toList());

  /// Replace list for a specific mode (not necessarily active).
  void setListFor(CalendarMode mode, List<SchedulePoint> pts) {
    final s = state;
    if (s is! DeviceScheduleReady) return;
    final lists = Map<CalendarMode, List<SchedulePoint>>.from(s.snap.lists);
    lists[mode] = _sortedDedup(pts.map(_norm).toList());
    emit(s.copyWith(snap: s.snap.copyWith(lists: lists), dirty: true, flash: null));
  }

  // ---------------- Persist (bundle) ----------------

  Future<void> persistAll() async {
    final s = state;
    if (s is! DeviceScheduleReady || s.saving) return;
    emit(s.copyWith(saving: true, flash: null));
    try {
      await _saveAll(_deviceSn, s.snap);
      emit(s.copyWith(saving: false, dirty: false, flash: 'Saved'));
      _clearFlashSoon();
    } catch (e) {
      emit(s.copyWith(saving: false, flash: 'Failed: ${e.toString()}'));
      _clearFlashSoon();
    }
  }

  // ---------------- Current / Next (active list) ----------------

  SchedulePoint? currentPoint({DateTime? now}) {
    final pts = state.points;
    if (pts.isEmpty) return null;
    now ??= DateTime.now();
    return _currentFor(pts, now);
  }

  SchedulePoint? nextPoint({DateTime? now}) {
    final pts = state.points;
    if (pts.isEmpty) return null;
    now ??= DateTime.now();
    return _nextFor(pts, now);
  }

  // ---------------- Internals ----------------

  void _mutateActive(List<SchedulePoint> Function(List<SchedulePoint>) f) {
    final s = state;
    if (s is! DeviceScheduleReady) return;
    final id = s.snap.mode;
    final lists = Map<CalendarMode, List<SchedulePoint>>.from(s.snap.lists);
    final before = lists[id] ?? const <SchedulePoint>[];
    final after = _sortedDedup(f(before));
    lists[id] = after;
    emit(s.copyWith(snap: s.snap.copyWith(lists: lists), dirty: true, flash: null));
  }

  SchedulePoint _norm(SchedulePoint p) {
    final hh = p.time.hour.clamp(0, 23);
    final mm = p.time.minute.clamp(0, 59);
    final dm = p.daysMask & WeekdayMask.all;
    final lo = (p.min <= p.max) ? p.min : p.max;
    final hi = (p.max >= p.min) ? p.max : p.min;
    return SchedulePoint(
      time: TimeOfDay(hour: hh, minute: mm),
      daysMask: dm,
      min: double.parse(lo.toStringAsFixed(1)),
      max: double.parse(hi.toStringAsFixed(1)),
    );
  }

  List<SchedulePoint> _sortedDedup(List<SchedulePoint> pts) {
    final map = <String, SchedulePoint>{};
    for (final p in pts) {
      final key = '${p.daysMask}:${p.time.hour}:${p.time.minute}';
      map[key] = p; // last wins
    }
    final out = map.values.toList()
      ..sort((a, b) {
        final ai = a.time.hour * 60 + a.time.minute;
        final bi = b.time.hour * 60 + b.time.minute;
        if (ai != bi) return ai.compareTo(bi);
        return a.daysMask.compareTo(b.daysMask);
      });
    return out;
  }

  int _todMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  SchedulePoint? _currentFor(List<SchedulePoint> pts, DateTime now) {
    for (int d = 0; d < 7; d++) {
      final day = now.subtract(Duration(days: d));
      final todays = pts.where((p) => WeekdayMask.has(p.daysMask, _weekdayBit(day))).toList()
        ..sort((a, b) => _todMinutes(a.time).compareTo(_todMinutes(b.time)));
      if (todays.isEmpty) continue;
      final m = _todMinutes(TimeOfDay(hour: day.hour, minute: day.minute));
      final idx = (d == 0) ? todays.lastIndexWhere((p) => _todMinutes(p.time) <= m) : todays.length - 1;
      if (idx >= 0) return todays[idx];
    }
    return null;
  }

  SchedulePoint? _nextFor(List<SchedulePoint> pts, DateTime now) {
    for (int d = 0; d < 7; d++) {
      final day = now.add(Duration(days: d));
      final todays = pts.where((p) => WeekdayMask.has(p.daysMask, _weekdayBit(day))).toList()
        ..sort((a, b) => _todMinutes(a.time).compareTo(_todMinutes(b.time)));
      if (todays.isEmpty) continue;
      final m =
          _todMinutes(d == 0 ? TimeOfDay(hour: now.hour, minute: now.minute) : const TimeOfDay(hour: 0, minute: 0));
      final idx = todays.indexWhere((p) => _todMinutes(p.time) > m);
      if (idx >= 0) return todays[idx];
    }
    return null;
  }

  int _weekdayBit(DateTime dt) => 1 << ((dt.weekday - 1) % 7);

  void _clearFlashSoon() {
    scheduleMicrotask(() {
      final s = state;
      if (s is DeviceScheduleReady && s.flash != null) {
        emit(s.copyWith(flash: null));
      }
    });
  }
}
