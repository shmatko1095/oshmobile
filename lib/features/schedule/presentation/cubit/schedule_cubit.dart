import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/services/mqtt_op_runner.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/serial_executor.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/usecases/fetch_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/save_schedule_all.dart';
import 'package:oshmobile/features/schedule/domain/usecases/set_schedule_mode.dart';
import 'package:oshmobile/features/schedule/domain/usecases/watch_schedule_stream.dart';

part 'schedule_state.dart';

/// Device-scoped schedule cubit: one instance per deviceSn.
///
/// Principles:
/// - ACK/timeout handled ONLY in repository/usecase.
/// - Cubit maintains base/draft and UI-friendly state.
/// - Network ops serialized to avoid overlap.
/// - Latest-wins intents while saving are stored in state (queued).
class DeviceScheduleCubit extends Cubit<DeviceScheduleState> {
  final String deviceSn;

  final FetchScheduleAll _fetchAll;
  final SaveScheduleAll _saveAll;
  final SetScheduleMode _setMode;
  final WatchScheduleStream _watchSchedule;
  final MqttCommCubit _comm;

  late final SerialExecutor _serial = SerialExecutor();
  late final MqttOpRunner _ops = MqttOpRunner(deviceSn: deviceSn, serial: _serial, comm: _comm);

  StreamSubscription<MapEntry<String?, CalendarSnapshot>>? _snapSub;
  bool _watchStarted = false;

  static const _listEq = DeepCollectionEquality();

  DeviceScheduleCubit({
    required this.deviceSn,
    required FetchScheduleAll fetchAll,
    required SaveScheduleAll saveAll,
    required SetScheduleMode setMode,
    required WatchScheduleStream watchSchedule,
    required MqttCommCubit comm,
  })  : _fetchAll = fetchAll,
        _saveAll = saveAll,
        _setMode = setMode,
        _watchSchedule = watchSchedule,
        _comm = comm,
        super(const DeviceScheduleLoading());

  /// Call once after creation to start reported stream (from DeviceScope).
  void start() {
    if (_watchStarted) return;
    _watchStarted = true;

    _snapSub = _watchSchedule(deviceSn).listen((entry) {
      _applyReported(appliedReqId: entry.key, remote: entry.value);
    });
  }

  Future<void> refresh() => _serial.run(() async {
        final prev = state;

        if (prev is! DeviceScheduleReady) {
          emit(DeviceScheduleLoading(modeHint: prev.mode));
        }

        final snap = await _fetchAll(deviceSn);
        if (isClosed) return;

        final st = _readyOrNull();
        if (st != null) {
          emit(_rebaseOnNewBase(st, snap));
        } else {
          emit(DeviceScheduleReady(base: snap));
        }
      });

  // ---------------------------------------------------------------------------
  // Operations (latest wins)
  // ---------------------------------------------------------------------------

  Future<void> setMode(CalendarMode next) {
    final st = _readyOrNull();
    if (st == null) return Future.value();

    // No-op if mode is already effective (prevents extra MQTT call on page open).
    final effective = st.modeOverride ?? st.base.mode;
    if (next == effective) return Future.value();

    // If saving: update draft immediately + store last intent.
    if (st.saving) {
      emit(st.copyWith(modeOverride: next, queued: st.queued.withMode(next), flash: null));
      return Future.value();
    }

    final reqId = newReqId();
    _comm.start(reqId: reqId, deviceSn: deviceSn);

    // Mark pending op + optimistic UI.
    emit(st.copyWith(
      modeOverride: next,
      saving: true,
      pending: SchedulePending(reqId: reqId, kind: SchedulePendingKind.mode),
      queued: st.queued.clearMode(),
      flash: null,
    ));

    return _ops.run(
      reqId: reqId,
      op: () => _setMode(deviceSn, next, reqId: reqId),
      timeoutReason: 'Schedule mode ACK timeout',
      errorReason: 'Failed to set schedule mode',
      extraContext: const {},
      timeoutCommMessage: 'Operation timed out',
      errorCommMessage: (e) => 'Failed to set mode: $e',
      onSuccess: () {
        if (isClosed) return;
        final cur = _readyOrNull();
        if (cur == null) return;

        final newBase = cur.base.copyWith(mode: next);
        emit(_rebaseOnNewBase(cur, newBase).copyWith(saving: false, clearPending: true, flash: null));
      },
      onTimeout: () => _onTimeout(),
      onError: (_) => _onFailed("Failed to set mode"),
      onFinally: _flushQueuedIfAny,
    );
  }

  Future<void> saveAll() {
    final st = _readyOrNull();
    if (st == null) return Future.value();

    // Nothing to save.
    if (!st.dirty) return Future.value();

    // If saving: remember there was an extra save request (once).
    if (st.saving) {
      emit(st.copyWith(queued: st.queued.withSaveAll(), flash: null));
      return Future.value();
    }

    final reqId = newReqId();
    final desired = st.snap;

    _comm.start(reqId: reqId, deviceSn: deviceSn);

    emit(st.copyWith(
      saving: true,
      pending: SchedulePending(reqId: reqId, kind: SchedulePendingKind.saveAll),
      queued: st.queued.clearSaveAll(),
      flash: null,
    ));

    return _ops.run(
      reqId: reqId,
      op: () => _saveAll(deviceSn, desired, reqId: reqId),
      timeoutReason: 'Schedule saveAll ACK timeout',
      errorReason: 'Failed to save schedule',
      timeoutCommMessage: 'Operation timed out',
      errorCommMessage: (e) => 'Failed to save schedule: $e',
      onSuccess: () {
        if (isClosed) return;
        final cur = _readyOrNull();
        if (cur == null) return;

        emit(_rebaseOnNewBase(cur, desired).copyWith(saving: false, clearPending: true, flash: null));
      },
      onTimeout: _onTimeout,
      onError: (_) => _onFailed("Failed to save schedule"),
      onFinally: _flushQueuedIfAny,
    );
  }

  // ---------------------------------------------------------------------------
  // Reported stream
  // ---------------------------------------------------------------------------
  void _applyReported({required String? appliedReqId, required CalendarSnapshot remote}) {
    if (isClosed) return;

    final st = _readyOrNull();
    if (st == null) {
      emit(DeviceScheduleReady(base: remote));
      return;
    }

    final rebased = _rebaseOnNewBase(st, remote);

    final isAckForPending = appliedReqId != null && st.pending?.reqId == appliedReqId;
    if (isAckForPending) {
      _comm.complete(appliedReqId);
    }

    emit(rebased.copyWith(saving: isAckForPending ? false : rebased.saving, clearPending: isAckForPending));
    if (isAckForPending) _flushQueuedIfAny();
  }

  void _flushQueuedIfAny() {
    if (isClosed) return;

    final st = _readyOrNull();
    if (st == null) return;
    if (st.saving) return;

    final q = st.queued;
    if (q.isEmpty) return;

    // Priority: one extra save.
    if (q.saveAll) {
      emit(st.copyWith(queued: q.clearSaveAll()));
      if (st.dirty) unawaited(saveAll());
      return;
    }

    // Otherwise: last requested mode.
    final m = q.mode;
    if (m != null) {
      emit(st.copyWith(queued: q.clearMode()));
      if (m != st.base.mode) unawaited(setMode(m));
    }
  }

  // ---------------------------------------------------------------------------
  // Local editing (base/draft)
  // ---------------------------------------------------------------------------

  void addPoint([SchedulePoint? p, int stepMinutes = 15]) {
    final st = _readyOrNull();
    if (st == null) return;

    final mode = st.mode;
    final current = List<SchedulePoint>.from(st.listFor(mode));
    final point = p ?? _makeDefaultPoint(current, mode, stepMinutes);

    current.add(point);
    setListFor(mode, current);
  }

  void changePoint(int index, SchedulePoint p) {
    final st = _readyOrNull();
    if (st == null) return;

    final mode = st.mode;
    final current = List<SchedulePoint>.from(st.listFor(mode));
    if (index < 0 || index >= current.length) return;

    current[index] = p;
    setListFor(mode, current);
  }

  void removeAt(int index) {
    final st = _readyOrNull();
    if (st == null) return;

    final mode = st.mode;
    final current = List<SchedulePoint>.from(st.listFor(mode));
    if (index < 0 || index >= current.length) return;

    current.removeAt(index);
    setListFor(mode, current);
  }

  void replaceAll(List<SchedulePoint> points) {
    final st = _readyOrNull();
    if (st == null) return;
    setListFor(st.mode, points);
  }

  void setListFor(CalendarMode id, List<SchedulePoint> pts) {
    final st = _readyOrNull();
    if (st == null) return;

    final normalized = _sortedDedup(pts);
    final nextOverrides = Map<CalendarMode, List<SchedulePoint>>.from(st.listOverrides);

    final baseList = st.base.pointsFor(id);
    if (_listEq.equals(baseList, normalized)) {
      nextOverrides.remove(id);
    } else {
      nextOverrides[id] = normalized;
    }

    emit(st.copyWith(listOverrides: Map.unmodifiable(nextOverrides), flash: null));
  }

  // ---------------------------------------------------------------------------
  // Current / Next helpers
  // ---------------------------------------------------------------------------

  SchedulePoint? currentPoint({DateTime? now}) {
    final pts = state.points;
    if (pts.isEmpty) return null;
    now ??= DateTime.now();

    if (state.mode == CalendarMode.weekly) {
      return _currentForWeekly(pts, now);
    }
    return _currentFor(pts, now);
  }

  SchedulePoint? nextPoint({DateTime? now}) {
    if (state.mode == CalendarMode.daily || state.mode == CalendarMode.weekly) {
      final pts = state.points;
      if (pts.isEmpty) return null;
      now ??= DateTime.now();

      if (state.mode == CalendarMode.weekly) {
        return _nextForWeekly(pts, now);
      }
      return _nextFor(pts, now);
    } else {
      return null;
    }
  }

  SchedulePoint? _currentForWeekly(List<SchedulePoint> pts, DateTime now) {
    final nowMin = now.hour * 60 + now.minute;
    final nowWeekMin = (now.weekday - 1) * 1440 + nowMin;

    SchedulePoint? best;
    var bestWeekMin = -1;

    SchedulePoint? wrap;
    var wrapWeekMin = -1;

    for (final p in pts) {
      final t = p.time.hour * 60 + p.time.minute;

      for (var wd = 1; wd <= 7; wd++) {
        if (!WeekdayMask.includes(p.daysMask, wd)) continue;

        final w = (wd - 1) * 1440 + t;

        if (w <= nowWeekMin && w > bestWeekMin) {
          bestWeekMin = w;
          best = p;
        }
        if (w > wrapWeekMin) {
          wrapWeekMin = w;
          wrap = p;
        }
      }
    }

    return best ?? wrap;
  }

  SchedulePoint? _nextForWeekly(List<SchedulePoint> pts, DateTime now) {
    final nowMin = now.hour * 60 + now.minute;
    final nowWeekMin = (now.weekday - 1) * 1440 + nowMin;

    SchedulePoint? best;
    var bestWeekMin = 1 << 30;

    SchedulePoint? wrap;
    var wrapWeekMin = 1 << 30;

    for (final p in pts) {
      final t = p.time.hour * 60 + p.time.minute;

      for (var wd = 1; wd <= 7; wd++) {
        if (!WeekdayMask.includes(p.daysMask, wd)) continue;

        final w = (wd - 1) * 1440 + t;

        if (w > nowWeekMin && w < bestWeekMin) {
          bestWeekMin = w;
          best = p;
        }
        if (w < wrapWeekMin) {
          wrapWeekMin = w;
          wrap = p;
        }
      }
    }

    return best ?? wrap;
  }

  SchedulePoint? _currentFor(List<SchedulePoint> pts, DateTime now) {
    final curMin = now.hour * 60 + now.minute;

    SchedulePoint? best;
    var bestMin = -1;

    for (final p in pts) {
      final m = p.time.hour * 60 + p.time.minute;
      if (m <= curMin && m > bestMin) {
        bestMin = m;
        best = p;
      }
    }

    if (best == null && pts.isNotEmpty) {
      best = pts.reduce((a, b) {
        final am = a.time.hour * 60 + a.time.minute;
        final bm = b.time.hour * 60 + b.time.minute;
        return am >= bm ? a : b;
      });
    }

    return best;
  }

  SchedulePoint? _nextFor(List<SchedulePoint> pts, DateTime now) {
    final curMin = now.hour * 60 + now.minute;

    SchedulePoint? best;
    var bestMin = 2000;

    for (final p in pts) {
      final m = p.time.hour * 60 + p.time.minute;
      if (m > curMin && m < bestMin) {
        bestMin = m;
        best = p;
      }
    }

    if (best == null && pts.isNotEmpty) {
      best = pts.reduce((a, b) {
        final am = a.time.hour * 60 + a.time.minute;
        final bm = b.time.hour * 60 + b.time.minute;
        return am <= bm ? a : b;
      });
    }

    return best;
  }

  // ---------------------------------------------------------------------------
  // Rebase (base/draft)
  // ---------------------------------------------------------------------------

  DeviceScheduleReady _rebaseOnNewBase(DeviceScheduleReady st, CalendarSnapshot newBase) {
    CalendarMode? nextModeOverride = st.modeOverride;
    if (nextModeOverride != null && nextModeOverride == newBase.mode) {
      nextModeOverride = null;
    }

    final nextListOverrides = <CalendarMode, List<SchedulePoint>>{};
    st.listOverrides.forEach((mode, list) {
      final baseList = newBase.pointsFor(mode);
      if (!_listEq.equals(baseList, list)) {
        nextListOverrides[mode] = list;
      }
    });

    return st.copyWith(
      base: newBase,
      modeOverride: nextModeOverride,
      removeModeOverride: nextModeOverride == null,
      listOverrides: Map.unmodifiable(nextListOverrides),
    );
  }

  DeviceScheduleReady? _readyOrNull() {
    final st = state;
    return st is DeviceScheduleReady ? st : null;
  }

  // ---------------------------------------------------------------------------
  // Scheduling math helpers
  // ---------------------------------------------------------------------------

  SchedulePoint _makeDefaultPoint(List<SchedulePoint> current, CalendarMode mode, int stepMinutes) {
    final now = TimeOfDay.now();
    final t = _nextFreeTime(current, now, stepMinutes);

    final last = current.isNotEmpty ? _norm(current.last) : null;

    final daysMask = mode == CalendarMode.weekly ? (last?.daysMask ?? WeekdayMask.all) : WeekdayMask.all;
    final minV = last?.min ?? 20.0;
    final maxV = last?.max ?? 22.0;

    return SchedulePoint(time: t, daysMask: daysMask, min: minV, max: maxV);
  }

  SchedulePoint _norm(SchedulePoint p) {
    final hh = p.time.hour.clamp(0, 23);
    final mm = p.time.minute.clamp(0, 59);
    final dm = p.daysMask & WeekdayMask.all;

    final lo = (p.min <= p.max) ? p.min : p.max;
    final hi = (p.max >= p.min) ? p.max : p.min;

    return SchedulePoint(time: TimeOfDay(hour: hh, minute: mm), daysMask: dm, min: lo, max: hi);
  }

  List<SchedulePoint> _sortedDedup(List<SchedulePoint> pts) {
    final out = pts.map(_norm).toList(growable: false);

    out.sort((a, b) {
      final at = a.time.hour * 60 + a.time.minute;
      final bt = b.time.hour * 60 + b.time.minute;
      if (at != bt) return at.compareTo(bt);

      if (a.daysMask != b.daysMask) return a.daysMask.compareTo(b.daysMask);

      final c1 = a.min.compareTo(b.min);
      if (c1 != 0) return c1;

      return a.max.compareTo(b.max);
    });

    final result = <SchedulePoint>[];
    for (final p in out) {
      if (result.isEmpty) {
        result.add(p);
        continue;
      }

      final prev = result.last;
      final sameKey = prev.time.hour == p.time.hour && prev.time.minute == p.time.minute && prev.daysMask == p.daysMask;

      if (sameKey) {
        result[result.length - 1] = p;
      } else {
        result.add(p);
      }
    }

    return List.unmodifiable(result);
  }

  TimeOfDay _nextFreeTime(List<SchedulePoint> pts, TimeOfDay start, int stepMinutes) {
    final used = <int>{};
    for (final p in pts) {
      used.add(p.time.hour * 60 + p.time.minute);
    }

    final startMin = start.hour * 60 + start.minute;
    final candidate = ((startMin + stepMinutes - 1) ~/ stepMinutes) * stepMinutes;

    for (var i = 0; i < 1440 ~/ stepMinutes; i++) {
      final m = (candidate + i * stepMinutes) % 1440;
      if (!used.contains(m)) {
        return TimeOfDay(hour: m ~/ 60, minute: m % 60);
      }
    }

    return start;
  }

  void _onTimeout() {
    if (isClosed) return;
    final cur = _readyOrNull();
    if (cur == null) return;

    emit(cur.copyWith(saving: false, clearPending: true, flash: 'Operation timed out'));
  }

  void _onFailed(String msg) {
    if (isClosed) return;
    final cur = _readyOrNull();
    if (cur == null) return;

    emit(cur.copyWith(saving: false, clearPending: true, flash: msg));
  }

  @override
  Future<void> close() async {
    try {
      await _snapSub?.cancel();
    } catch (_) {}
    return super.close();
  }
}
