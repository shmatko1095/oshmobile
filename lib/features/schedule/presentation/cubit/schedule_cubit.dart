// lib/features/schedule/presentation/cubit/schedule_cubit.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/schedule_models.dart';
import '../../domain/usecases/fetch_schedule.dart';
import '../../domain/usecases/save_schedule.dart';

/// -------------------- State --------------------

sealed class ScheduleState {
  const ScheduleState();
}

/// Loading a concrete [mode] (kept to render proper skeletons).
class ScheduleLoading extends ScheduleState {
  final CalendarMode mode;

  const ScheduleLoading(this.mode);
}

/// Hard error; UI may show retry with the same [mode].
class ScheduleError extends ScheduleState {
  final CalendarMode mode;
  final String message;

  const ScheduleError(this.mode, this.message);
}

/// Ready to edit.
/// [dirty] — there are in-memory edits not yet persisted;
/// [saving] — a save() call is in flight (UI may disable controls);
/// [flash] — ephemeral one-shot notification (success/error).
class ScheduleReady extends ScheduleState {
  final CalendarMode mode;
  final List<SchedulePoint> points;
  final bool dirty;
  final bool saving;
  final String? flash;

  const ScheduleReady({
    required this.mode,
    required this.points,
    this.dirty = false,
    this.saving = false,
    this.flash,
  });

  ScheduleReady copyWith({
    CalendarMode? mode,
    List<SchedulePoint>? points,
    bool? dirty,
    bool? saving,
    String? flash, // pass null to clear, omit to keep
  }) {
    return ScheduleReady(
      mode: mode ?? this.mode,
      points: points ?? this.points,
      dirty: dirty ?? this.dirty,
      saving: saving ?? this.saving,
      flash: flash,
    );
  }
}

/// -------------------- Cubit --------------------

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit({
    required String deviceId,
    required FetchSchedule fetch,
    required SaveSchedule save,
    CalendarMode initialMode = CalendarMode.weekly,
  })  : _deviceId = deviceId,
        _fetch = fetch,
        _save = save,
        super(ScheduleLoading(initialMode)) {
    load(initialMode);
  }

  final String _deviceId;
  final FetchSchedule _fetch;
  final SaveSchedule _save;

  int _loadToken = 0; // protects against out-of-order async loads

  /// Load snapshot for a specific calendar [mode].
  Future<void> load(CalendarMode mode) async {
    final token = ++_loadToken;
    emit(ScheduleLoading(mode));
    try {
      final pts = await _fetch(_deviceId, mode);
      if (token != _loadToken) return; // stale
      emit(ScheduleReady(mode: mode, points: _sortedDedup(pts)));
    } catch (e) {
      if (token != _loadToken) return;
      emit(ScheduleError(mode, e.toString()));
    }
  }

  /// Convenience for UI switches.
  Future<void> setMode(CalendarMode mode) => load(mode);

  /// Persist current points to the device (if in ready state).
  Future<void> persist() async {
    final s = state;
    if (s is! ScheduleReady || s.saving) return;
    // If there is nothing to save and not dirty — ignore.
    // We still allow save even if !dirty, in case UI wants a forced sync.
    emit(s.copyWith(saving: true, flash: null));
    try {
      await _save(_deviceId, s.mode, s.points);
      // Repository waits for ACK internally (or you can keep optimistic semantics).
      emit(s.copyWith(saving: false, dirty: false, flash: 'Saved'));
      // Clear flash after a tick so snackbar/toast is one-shot.
      _clearFlashSoon();
    } catch (e) {
      emit(s.copyWith(saving: false, flash: 'Failed: ${e.toString()}'));
      _clearFlashSoon();
    }
  }

  // --------------- Mutations (optimistic) ---------------

  /// Change time of a point. Duplicate guard (time + daysMask).
  void changeTime(int index, TimeOfDay time) {
    final s = state;
    if (s is! ScheduleReady) return;
    if (index < 0 || index >= s.points.length) return;

    final pts = [...s.points];
    final candidate = pts[index].copyWith(time: _clampTime(time));

    if (_hasDuplicateKey(pts, candidate, exceptIndex: index)) {
      _flash('Time with the same days already exists');
      return;
    }

    pts[index] = candidate;
    emit(s.copyWith(points: _sortedDedup(pts), dirty: true, flash: null));
  }

  /// Change temperature value.
  void changeTemp(int index, double newTemp) {
    final s = state;
    if (s is! ScheduleReady) return;
    if (index < 0 || index >= s.points.length) return;

    final pts = [...s.points];
    pts[index] = pts[index].copyWith(temperature: newTemp);
    emit(s.copyWith(points: pts, dirty: true, flash: null));
  }

  /// Toggle weekday bit (weekly mode only). Duplicate guard (time + daysMask).
  void toggleDay(int index, int dayBit) {
    final s = state;
    if (s is! ScheduleReady) return;
    if (s.mode == CalendarMode.daily) return; // daysMask not applicable
    if (index < 0 || index >= s.points.length) return;

    final pts = [...s.points];
    final p = pts[index];
    final newMask = p.daysMask ^ dayBit; // toggle bit
    final candidate = p.copyWith(daysMask: newMask);

    if (_hasDuplicateKey(pts, candidate, exceptIndex: index)) {
      _flash('Time with the same days already exists');
      return;
    }

    pts[index] = candidate;
    emit(s.copyWith(points: _sortedDedup(pts), dirty: true, flash: null));
  }

  /// Add a new point with duplicate guard.
  void addPoint(SchedulePoint p) {
    final s = state;
    if (s is! ScheduleReady) return;

    if (_hasDuplicateKey(s.points, p)) {
      _flash('Time with the same days already exists');
      return;
    }

    final pts = [...s.points, _normalizedPoint(p)];
    emit(s.copyWith(points: _sortedDedup(pts), dirty: true, flash: null));
  }

  /// Remove a point at index.
  void removeAt(int index) {
    final s = state;
    if (s is! ScheduleReady) return;
    if (index < 0 || index >= s.points.length) return;

    final pts = [...s.points]..removeAt(index);
    emit(s.copyWith(points: pts, dirty: true, flash: null));
  }

  /// Replace entire list (e.g., import template). Validates & sorts.
  void replaceAll(List<SchedulePoint> next) {
    final s = state;
    if (s is! ScheduleReady) return;
    emit(s.copyWith(points: _sortedDedup(next.map(_normalizedPoint).toList()), dirty: true, flash: null));
  }

  /// Shortcut for UI save button (optimistic save is handled in [persist]).
  Future<void> save() => persist();

  // --------------- Helpers ---------------

  void _flash(String msg) {
    final s = state;
    if (s is! ScheduleReady) return;
    emit(s.copyWith(flash: msg));
    _clearFlashSoon();
  }

  void _clearFlashSoon() {
    // Clear in next microtask to allow snackbar listeners to react once.
    scheduleMicrotask(() {
      final s = state;
      if (s is ScheduleReady && s.flash != null) {
        emit(s.copyWith(flash: null));
      }
    });
  }

  bool _sameTime(TimeOfDay a, TimeOfDay b) => a.hour == b.hour && a.minute == b.minute;

  /// Duplicate means same (time + daysMask) except an optional [exceptIndex].
  bool _hasDuplicateKey(List<SchedulePoint> pts, SchedulePoint cand, {int? exceptIndex}) {
    for (int i = 0; i < pts.length; i++) {
      if (exceptIndex != null && i == exceptIndex) continue;
      final p = pts[i];
      if (_sameTime(p.time, cand.time) && p.daysMask == cand.daysMask) {
        return true;
      }
    }
    return false;
  }

  /// Normalize incoming point (clamp time, round temp if you wish, etc.).
  SchedulePoint _normalizedPoint(SchedulePoint p) => p.copyWith(time: _clampTime(p.time));

  TimeOfDay _clampTime(TimeOfDay t) => TimeOfDay(hour: t.hour.clamp(0, 23), minute: t.minute.clamp(0, 59));

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
