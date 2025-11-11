import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/usecases/fetch_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/save_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/set_schedule_mode.dart';
import 'package:oshmobile/features/schedule/domain/usecases/watch_schedule_stream.dart';

part 'schedule_state.dart';

class DeviceScheduleCubit extends Cubit<DeviceScheduleState> {
  final FetchScheduleAll _fetchAll;
  final SaveScheduleAll _saveAll;
  final SetScheduleMode _setMode;
  final WatchScheduleStream _watchSchedule;

  /// ACK wait timeout for each command.
  final Duration ackTimeout;

  DeviceScheduleCubit({
    required FetchScheduleAll fetchAll,
    required SaveScheduleAll saveAll,
    required SetScheduleMode setMode,
    required WatchScheduleStream watchSchedule,
    this.ackTimeout = const Duration(seconds: 6),
  })  : _fetchAll = fetchAll,
        _saveAll = saveAll,
        _setMode = setMode,
        _watchSchedule = watchSchedule,
        super(const DeviceScheduleLoading());

  StreamSubscription<MapEntry<String?, CalendarSnapshot>>? _snapSub;
  final Map<String, Timer> _pendingTimers = <String, Timer>{};

  String _deviceSn = '';
  int _bindToken = 0;

  @override
  Future<void> close() {
    _snapSub?.cancel();
    _cancelAllPendingTimers();
    return super.close();
  }

  Future<void> rebind() async => bind(_deviceSn);

  // ---------------- Bind & load ----------------
  Future<void> bind(String deviceSn) async {
    _deviceSn = deviceSn;
    final token = ++_bindToken;

    // Reset transient state on new bind.
    final cur = state;
    if (cur is DeviceScheduleReady) {
      _cancelAllPendingTimers();
      emit(cur.copyWith(
        saving: false,
        flash: null,
        dirty: false,
        pendingQueue: const <PendingTxn>[],
      ));
    }

    await _snapSub?.cancel();
    _snapSub = _watchSchedule(deviceSn).listen((entry) {
      if (token != _bindToken) return;
      _onReported(entry.key, entry.value);
    });

    emit(const DeviceScheduleLoading());

    try {
      final snap = await _fetchAll(deviceSn);
      if (token != _bindToken) return;

      final s = state;
      if (s is DeviceScheduleReady && (s.dirty || s.saving)) return;

      if (s is! DeviceScheduleReady) {
        emit(DeviceScheduleReady(snap: _withSafeMode(snap)));
      }
    } catch (e) {
      if (token != _bindToken) return;
      emit(DeviceScheduleError(e.toString()));
    }
  }

  // ---------------- Mode API ----------------
  CalendarMode getMode() => state.mode;

  /// Optimistic mode change; we enqueue op with reqId and wait reported acks.
  void setMode(CalendarMode next) {
    final s = state;
    if (s is! DeviceScheduleReady) return;
    if (s.snap.mode.id == next.id) return;

    final reqId = newReqId();
    final before = s.snap;
    final desired = s.snap.copyWith(mode: next);

    final q = List<PendingTxn>.from(s.pendingQueue)
      ..add(PendingTxn(
        reqId: reqId,
        beforeSnap: before,
        desiredSnap: desired,
        deadline: DateTime.now().add(ackTimeout),
        kind: 'mode',
        desiredMode: next,
      ));

    // Optimistic UI (we also keep s.snap updated for immediate widgets)
    emit(s.copyWith(
      snap: desired,
      saving: true,
      dirty: false,
      flash: null,
      pendingQueue: q,
    ));
    _armTimer(reqId);

    unawaited(_setMode(_deviceSn, next, reqId: reqId).catchError((e) {
      _onPublishError(reqId, 'Failed to set mode: $e');
    }));
  }

  // ---------------- Persist (bundle) ----------------

  Future<void> persistAll() async {
    final s = state;
    if (s is! DeviceScheduleReady) return;

    final reqId = newReqId();
    final before = s.snap;
    final desired = s.snap; // we already hold edited lists/mode in snap

    final q = List<PendingTxn>.from(s.pendingQueue)
      ..add(PendingTxn(
        reqId: reqId,
        beforeSnap: before,
        desiredSnap: desired,
        deadline: DateTime.now().add(ackTimeout),
        kind: 'saveAll',
      ));
    emit(s.copyWith(
      saving: true,
      flash: null,
      pendingQueue: q,
    ));
    _armTimer(reqId);

    try {
      await _saveAll(_deviceSn, desired, reqId: reqId);
      // Wait for reported to drain queue
    } catch (e) {
      _onPublishError(reqId, 'Failed to save: $e');
    }
  }

  void _onReported(String? appliedReqId, CalendarSnapshot remote) {
    final safe = _withSafeMode(remote);
    final st = state;
    if (st is! DeviceScheduleReady) {
      emit(DeviceScheduleReady(snap: safe));
      return;
    }

    if (st.pendingQueue.isNotEmpty) {
      // No correlation id -> we keep fully optimistic UI; do not adopt device snapshot.
      if (appliedReqId == null || appliedReqId.isEmpty) {
        emit(st.copyWith(saving: true)); // keep optimistic snap as-is
        return;
      }

      // Drop any txn(s) matched by this appliedReqId (acks may arrive out-of-order).
      final newQ = List<PendingTxn>.from(st.pendingQueue)..removeWhere((t) => t.reqId == appliedReqId);
      _pendingTimers.remove(appliedReqId)?.cancel();

      if (newQ.isEmpty) {
        // Queue drained -> adopt device snapshot (becomes the new confirmed base).
        emit(st.copyWith(
          snap: safe,
          saving: false,
          dirty: false,
          pendingQueue: newQ,
        ));
      } else {
        // Still pending -> remain optimistic; do not adopt device snapshot yet.
        emit(st.copyWith(
          pendingQueue: newQ,
          saving: true,
          // snap unchanged (optimistic)
        ));
      }
      return;
    }

    // No pending -> adopt reported normally (unless editing lists).
    if (st.dirty || st.saving) {
      emit(st.copyWith(snap: st.snap.copyWith(mode: safe.mode), saving: false));
    } else {
      emit(st.copyWith(snap: safe, dirty: false, saving: false));
    }
  }

  // ---------------- Pending timers & errors ----------------

  void _onPublishError(String reqId, String message) {
    final st = state;
    if (st is! DeviceScheduleReady) return;

    final idx = st.pendingQueue.indexWhere((t) => t.reqId == reqId);
    if (idx == -1) {
      emit(st.copyWith(saving: st.pendingQueue.isNotEmpty, flash: message));
      _clearFlashSoon();
      return;
    }

    final failed = st.pendingQueue[idx];
    _cancelAllPendingTimers();

    emit(st.copyWith(
      snap: failed.beforeSnap, // rollback to a consistent state
      saving: false,
      dirty: false,
      flash: message,
      pendingQueue: const <PendingTxn>[],
    ));
    _clearFlashSoon();
  }

  void _onTimeout(String reqId) {
    final st = state;
    if (st is! DeviceScheduleReady) return;
    final idx = st.pendingQueue.indexWhere((t) => t.reqId == reqId);
    if (idx == -1) return; // already acked

    final failed = st.pendingQueue[idx];
    _cancelAllPendingTimers();

    emit(st.copyWith(
      snap: failed.beforeSnap, // rollback to BEFORE the stuck op
      saving: false,
      dirty: false,
      flash: 'Operation timed out',
      pendingQueue: const <PendingTxn>[],
    ));
    _clearFlashSoon();
  }

  void _armTimer(String reqId) {
    _pendingTimers[reqId]?.cancel();
    _pendingTimers[reqId] = Timer(ackTimeout, () => _onTimeout(reqId));
  }

  void _cancelAllPendingTimers() {
    for (final t in _pendingTimers.values) {
      t.cancel();
    }
    _pendingTimers.clear();
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

  TimeOfDay _addMinutes(TimeOfDay t, int delta) {
    var total = (t.hour * 60 + t.minute + delta) % 1440;
    if (total < 0) total += 1440;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  bool _existsAt(List<SchedulePoint> pts, int daysMask, TimeOfDay t) {
    return pts.any(
      (p) => p.daysMask == daysMask && p.time.hour == t.hour && p.time.minute == t.minute,
    );
  }

  TimeOfDay _nextFreeTime(
    List<SchedulePoint> pts,
    int daysMask,
    TimeOfDay start, {
    int stepMinutes = 15,
  }) {
    var t = start;
    for (int i = 0; i < 1440; i += stepMinutes) {
      if (!_existsAt(pts, daysMask, t)) return t;
      t = _addMinutes(t, stepMinutes);
    }
    return start;
  }

  void addPoint([SchedulePoint? p, int stepMinutes = 15]) {
    final s = state;
    if (s is! DeviceScheduleReady) return;

    final mode = s.snap.mode;
    final current = List<SchedulePoint>.from(s.snap.lists[mode] ?? const <SchedulePoint>[]);

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

    var candidate = _norm(SchedulePoint(time: t, daysMask: daysMask, min: minV, max: maxV));

    final freeTime = _nextFreeTime(current, candidate.daysMask, candidate.time, stepMinutes: stepMinutes);
    if (freeTime != candidate.time) {
      candidate = candidate.copyWith(time: freeTime);
    }

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
        final ai = _todMinutes(a.time);
        final bi = _todMinutes(b.time);
        if (ai != bi) return ai.compareTo(bi);
        return a.daysMask.compareTo(b.daysMask);
      });
    return out;
  }

  int _todMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
  int _weekdayBit(DateTime dt) => 1 << ((dt.weekday - 1) % 7);

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
      final m = _todMinutes(
        d == 0 ? TimeOfDay(hour: now.hour, minute: now.minute) : const TimeOfDay(hour: 0, minute: 0),
      );
      final idx = todays.indexWhere((p) => _todMinutes(p.time) > m);
      if (idx >= 0) return todays[idx];
    }
    return null;
  }

  CalendarSnapshot _withSafeMode(CalendarSnapshot snap) {
    final ok = CalendarMode.all.any((m) => m.id == snap.mode.id);
    return ok ? snap : snap.copyWith(mode: CalendarMode.off);
  }

  void _clearFlashSoon() {
    scheduleMicrotask(() {
      final s = state;
      if (s is DeviceScheduleReady && s.flash != null) {
        emit(s.copyWith(flash: null));
      }
    });
  }
}
