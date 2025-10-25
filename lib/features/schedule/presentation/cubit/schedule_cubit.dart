import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../schedule/data/schedule_repository.dart';
import '../../../schedule/domain/models/schedule_models.dart';

sealed class ScheduleState {
  const ScheduleState();
}

class ScheduleLoading extends ScheduleState {
  const ScheduleLoading(this.mode);
  final CalendarMode mode;
}

class ScheduleError extends ScheduleState {
  const ScheduleError(this.mode, this.message);
  final CalendarMode mode;
  final String message;
}

class ScheduleReady extends ScheduleState {
  const ScheduleReady({
    required this.mode,
    required this.points,
    this.flash, // одноразовое сообщение (успех/ошибка)
  });

  final CalendarMode mode;
  final List<SchedulePoint> points;
  final String? flash;

  ScheduleReady copyWith({
    CalendarMode? mode,
    List<SchedulePoint>? points,
    String? flash,
  }) {
    return ScheduleReady(
      mode: mode ?? this.mode,
      points: points ?? this.points,
      flash: flash,
    );
  }
}

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit({
    required ScheduleRepository repo,
    required String deviceId,
  })  : _repo = repo,
        _deviceId = deviceId,
        super(const ScheduleLoading(CalendarMode.weekly));

  final ScheduleRepository _repo;
  final String _deviceId;

  Future<void> load(CalendarMode mode) async {
    emit(ScheduleLoading(mode));
    try {
      final pts = await _repo.fetchSchedule(_deviceId, mode);
      pts.sort(_cmpTime);
      emit(ScheduleReady(mode: mode, points: pts));
    } catch (e) {
      emit(ScheduleError(mode, e.toString()));
    }
  }

  void setMode(CalendarMode mode) => load(mode);

  // ---------- helpers ----------
  static int _cmpTime(SchedulePoint a, SchedulePoint b) {
    final ai = a.time.hour * 60 + a.time.minute;
    final bi = b.time.hour * 60 + b.time.minute;
    return ai.compareTo(bi);
  }

  bool _sameTime(TimeOfDay a, TimeOfDay b) => a.hour == b.hour && a.minute == b.minute;

  /// true -> есть точка с таким же временем и такой же маской дней
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

  void _flash(String msg) {
    final s = state;
    if (s is ScheduleReady) {
      emit(s.copyWith(flash: msg));
      emit(s.copyWith(flash: null));
    }
  }

  // ------- optimistic persist with rollback -------
  Future<void> _persist(ScheduleReady next, ScheduleState previous) async {
    emit(next); // оптимистично
    try {
      await _repo.saveSchedule(_deviceId, next.mode, next.points);
      // по желанию можно показать "Saved" — сейчас не шумим
      emit(next.copyWith(flash: null));
    } catch (e) {
      emit(previous); // откат
      if (previous is ScheduleReady) {
        emit(previous.copyWith(flash: 'Failed: ${e.toString()}'));
        emit(previous.copyWith(flash: null));
      } else if (previous is ScheduleLoading) {
        emit(ScheduleError(previous.mode, e.toString()));
      }
    }
  }

  // ------- mutations -------

  void changeTime(int index, TimeOfDay time) {
    final s = state;
    if (s is! ScheduleReady) return;

    final pts = [...s.points];
    final candidate = pts[index].copyWith(time: time);

    // запрет дубля (время + маска дней)
    if (_hasDuplicateKey(pts, candidate, exceptIndex: index)) {
      _flash('Time with the same days already exists');
      return;
    }

    pts[index] = candidate;
    pts.sort(_cmpTime);
    _persist(s.copyWith(points: pts), s);
  }

  void changeTemp(int index, double newTemp) {
    final s = state;
    if (s is! ScheduleReady) return;
    final pts = [...s.points];
    pts[index] = pts[index].copyWith(temperature: newTemp);
    // сортировка не нужна (время не менялось), но не мешает:
    // pts.sort(_cmpTime);
    _persist(s.copyWith(points: pts), s);
  }

  void toggleDay(int index, int dayBit) {
    final s = state;
    if (s is! ScheduleReady || s.mode == CalendarMode.daily) return;

    final pts = [...s.points];
    final newMask = WeekdayMask.toggle(pts[index].daysMask, dayBit);
    final candidate = pts[index].copyWith(daysMask: newMask);

    // запрет дубля (время + маска дней)
    if (_hasDuplicateKey(pts, candidate, exceptIndex: index)) {
      _flash('Time with the same days already exists');
      return;
    }

    pts[index] = candidate;
    // сортировка по времени сохраняем для стабильности
    pts.sort(_cmpTime);
    _persist(s.copyWith(points: pts), s);
  }

  void addPoint(SchedulePoint p) {
    final s = state;
    if (s is! ScheduleReady) return;

    // запрет дубля (время + маска дней)
    if (_hasDuplicateKey(s.points, p)) {
      _flash('Time with the same days already exists');
      return;
    }

    final pts = [...s.points, p]..sort(_cmpTime);
    _persist(s.copyWith(points: pts), s);
  }

  void removeAt(int index) {
    final s = state;
    if (s is! ScheduleReady) return;
    if (index < 0 || index >= s.points.length) return;
    final pts = [...s.points]..removeAt(index);
    _persist(s.copyWith(points: pts), s);
  }
}
