import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/usecases/fetch_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/save_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/set_schedule_mode.dart';
import 'package:oshmobile/features/schedule/domain/usecases/watch_schedule_stream.dart';

part 'schedule_state.dart';

/// Device-scoped schedule cubit: one instance per deviceSn.
class DeviceScheduleCubit extends Cubit<DeviceScheduleState> {
  final String deviceSn;

  final FetchScheduleAll _fetchAll;
  final SaveScheduleAll _saveAll;
  final SetScheduleMode _setMode;
  final WatchScheduleStream _watchSchedule;
  final MqttCommCubit _comm;

  /// ACK wait timeout for each command.
  final Duration ackTimeout;

  DeviceScheduleCubit({
    required this.deviceSn,
    required FetchScheduleAll fetchAll,
    required SaveScheduleAll saveAll,
    required SetScheduleMode setMode,
    required WatchScheduleStream watchSchedule,
    required MqttCommCubit comm,
    this.ackTimeout = const Duration(seconds: 4),
  })  : _fetchAll = fetchAll,
        _saveAll = saveAll,
        _setMode = setMode,
        _watchSchedule = watchSchedule,
        _comm = comm,
        super(const DeviceScheduleLoading());

  StreamSubscription<MapEntry<String?, CalendarSnapshot>>? _snapSub;
  final Map<String, Timer> _pendingTimers = <String, Timer>{};

  bool _watchStarted = false;

  /// Public API: reload initial snapshot from device (HTTP/MQTT behind usecase).
  Future<void> refresh() => _loadInitial();

  /// Call once after creation to start watch stream (from DeviceScope).
  void start() {
    if (_watchStarted) return;
    _watchStarted = true;

    _snapSub = _watchSchedule(deviceSn).listen((entry) {
      _onReported(entry.key, entry.value);
    });
  }

  Future<void> _loadInitial() async {
    if (isClosed) return;
    emit(const DeviceScheduleLoading());

    try {
      final snap = await _fetchAll(deviceSn);
      if (isClosed) return;
      emit(DeviceScheduleReady(snap: _withSafeMode(snap)));
    } catch (e, st) {
      if (isClosed) return;
      OshCrashReporter.logNonFatal(e, st, reason: "Failed to load schedule", context: {"deviceSn": deviceSn});
      emit(DeviceScheduleError(e.toString()));
    }
  }

  // ---------------- Mode API ----------------

  CalendarMode getMode() => state.mode;

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

    emit(s.copyWith(
      snap: desired,
      saving: true,
      dirty: false,
      flash: null,
      pendingQueue: q,
    ));

    _trackPendingReq(reqId);

    unawaited(_setMode(deviceSn, next, reqId: reqId).catchError((e) {
      _onPublishError(reqId, 'Failed to set mode: $e');
    }));
  }

  // ---------------- Persist ----------------

  Future<void> persistAll() async {
    final s = state;
    if (s is! DeviceScheduleReady) return;

    final reqId = newReqId();
    final before = s.snap;
    final desired = s.snap;

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

    _trackPendingReq(reqId);

    try {
      await _saveAll(deviceSn, desired, reqId: reqId);
      // Wait for reported ACK to drain queue.
    } catch (e) {
      _onPublishError(reqId, 'Failed to save: $e');
    }
  }

  // ---------------- Reported (ACK) ----------------

  void _onReported(String? appliedReqId, CalendarSnapshot remote) {
    if (isClosed) return;
    final safe = _withSafeMode(remote);

    final st = state;
    if (st is! DeviceScheduleReady) {
      emit(DeviceScheduleReady(snap: safe));
      return;
    }

    if (st.pendingQueue.isNotEmpty) {
      if (appliedReqId == null || appliedReqId.isEmpty) {
        emit(st.copyWith(saving: true));
        return;
      }

      final newQ = List<PendingTxn>.from(st.pendingQueue)..removeWhere((t) => t.reqId == appliedReqId);
      _pendingTimers.remove(appliedReqId)?.cancel();
      _comm.complete(appliedReqId);

      if (newQ.isEmpty) {
        emit(st.copyWith(
          snap: safe,
          saving: false,
          dirty: false,
          pendingQueue: newQ,
        ));
      } else {
        emit(st.copyWith(
          pendingQueue: newQ,
          saving: true,
        ));
      }
      return;
    }

    // No pending -> adopt normally (keep mode safe).
    if (st.dirty || st.saving) {
      emit(st.copyWith(snap: st.snap.copyWith(mode: safe.mode), saving: false));
    } else {
      emit(st.copyWith(snap: safe, dirty: false, saving: false));
    }
  }

  // ---------------- Pending timers & errors ----------------

  void _onPublishError(String reqId, String message) {
    if (isClosed) return;
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

    for (final txn in st.pendingQueue) {
      _comm.fail(txn.reqId, message);
    }

    OshCrashReporter.log("DeviceScheduleCubit: publish error: $message");
    emit(st.copyWith(
      snap: failed.beforeSnap,
      saving: false,
      dirty: false,
      flash: message,
      pendingQueue: const <PendingTxn>[],
    ));
    _clearFlashSoon();
  }

  void _onTimeout(String reqId) {
    if (isClosed) return;
    final st = state;
    if (st is! DeviceScheduleReady) return;

    final idx = st.pendingQueue.indexWhere((t) => t.reqId == reqId);
    if (idx == -1) return;

    final failed = st.pendingQueue[idx];
    _cancelAllPendingTimers();

    for (final txn in st.pendingQueue) {
      _comm.fail(txn.reqId, 'Operation timed out');
    }

    OshCrashReporter.log("Schedule operation timed out, deviceSn: $deviceSn");
    emit(st.copyWith(
      snap: failed.beforeSnap,
      saving: false,
      dirty: false,
      flash: 'Operation timed out',
      pendingQueue: const <PendingTxn>[],
    ));
    _clearFlashSoon();
  }

  void _trackPendingReq(String reqId) {
    _comm.start(reqId: reqId, deviceSn: deviceSn);
    _pendingTimers[reqId]?.cancel();
    _pendingTimers[reqId] = Timer(ackTimeout, () => _onTimeout(reqId));
  }

  void _cancelAllPendingTimers() {
    for (final t in _pendingTimers.values) {
      t.cancel();
    }
    _pendingTimers.clear();
  }

  // ---------------- Current / Next helpers (unchanged) ----------------

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
    return pts.any((p) => p.daysMask == daysMask && p.time.hour == t.hour && p.time.minute == t.minute);
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

  void setListFor(CalendarMode mode, List<SchedulePoint> pts) {
    final s = state;
    if (s is! DeviceScheduleReady) return;
    final lists = Map<CalendarMode, List<SchedulePoint>>.from(s.snap.lists);
    lists[mode] = _sortedDedup(pts.map(_norm).toList());
    emit(s.copyWith(snap: s.snap.copyWith(lists: lists), dirty: true, flash: null));
  }

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
      map[key] = p;
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

  SchedulePoint? _currentFor(List<SchedulePoint> pts, DateTime now) {
    if (pts.isEmpty) return null;
    final sorted = [...pts]..sort((a, b) => _todMinutes(a.time).compareTo(_todMinutes(b.time)));
    final nowMinutes = _todMinutes(TimeOfDay(hour: now.hour, minute: now.minute));
    final todayBit = WeekdayMask.weekdayBit(now);

    for (var i = sorted.length - 1; i >= 0; i--) {
      final p = sorted[i];
      if (!WeekdayMask.has(p.daysMask, todayBit)) continue;
      final t = _todMinutes(p.time);
      if (t <= nowMinutes) return p;
    }

    var dayBit = todayBit;
    for (var step = 0; step < 6; step++) {
      dayBit = WeekdayMask.prevDayBit(dayBit);
      for (var i = sorted.length - 1; i >= 0; i--) {
        final p = sorted[i];
        if (!WeekdayMask.has(p.daysMask, dayBit)) continue;
        return p;
      }
    }

    return null;
  }

  SchedulePoint? _nextFor(List<SchedulePoint> pts, DateTime now) {
    if (pts.length <= 1) return null;
    final sorted = [...pts]..sort((a, b) => _todMinutes(a.time).compareTo(_todMinutes(b.time)));
    final nowMinutes = _todMinutes(TimeOfDay(hour: now.hour, minute: now.minute));
    final todayBit = WeekdayMask.weekdayBit(now);

    for (var i = 0; i < sorted.length; i++) {
      final p = sorted[i];
      if (!WeekdayMask.has(p.daysMask, todayBit)) continue;
      final t = _todMinutes(p.time);
      if (t > nowMinutes) return p;
    }

    var dayBit = todayBit;
    for (var step = 0; step < 6; step++) {
      dayBit = WeekdayMask.nextDayBit(dayBit);
      for (var i = 0; i < sorted.length; i++) {
        final p = sorted[i];
        if (!WeekdayMask.has(p.daysMask, dayBit)) continue;
        return p;
      }
    }

    return null;
  }

  CalendarSnapshot _withSafeMode(CalendarSnapshot snap) {
    final ok = CalendarMode.all.any((m) => m.id == snap.mode.id);
    return ok ? snap : snap.copyWith(mode: CalendarMode.off);
  }

  void _clearFlashSoon() {
    scheduleMicrotask(() {
      if (isClosed) return;
      final s = state;
      if (s is DeviceScheduleReady && s.flash != null) {
        if (isClosed) return;
        emit(s.copyWith(flash: null));
      }
    });
  }

  @override
  Future<void> close() async {
    await _snapSub?.cancel();
    _snapSub = null;
    _cancelAllPendingTimers();

    // Remove any pending comm ops for this device when page is closed.
    _comm.dropForDevice(deviceSn);

    return super.close();
  }
}
