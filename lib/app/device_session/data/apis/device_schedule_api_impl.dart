import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/services/mqtt_op_runner.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/serial_executor.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/repositories/schedule_repository.dart';

class DeviceScheduleApiImpl implements DeviceScheduleApi {
  final String _deviceSn;
  final ScheduleRepository _repo;
  final MqttCommCubit _comm;
  final VoidCallback _onChanged;

  late final SerialExecutor _serial = SerialExecutor();
  late final MqttOpRunner _ops =
      MqttOpRunner(deviceSn: _deviceSn, serial: _serial, comm: _comm);

  final StreamController<CalendarSnapshot> _stream =
      StreamController<CalendarSnapshot>.broadcast();

  StreamSubscription<CalendarSnapshot>? _sub;
  bool _watchStarted = false;
  bool _disposed = false;

  CalendarSnapshot? _base;
  CalendarMode? _modeOverride;
  Map<CalendarMode, List<SchedulePoint>> _listOverrides =
      const <CalendarMode, List<SchedulePoint>>{};
  ScheduleRange? _rangeOverride;
  _ScheduleSavingKind? _savingKind;
  _ScheduleQueued _queued = const _ScheduleQueued();

  String? _flash;
  String? _loadError;
  CalendarMode _modeHint = CalendarMode.off;

  DeviceSlice<CalendarSnapshot> _slice =
      const DeviceSlice<CalendarSnapshot>.idle();

  static const _listEq = DeepCollectionEquality();

  DeviceScheduleApiImpl({
    required String deviceSn,
    required ScheduleRepository repo,
    required MqttCommCubit comm,
    required VoidCallback onChanged,
  })  : _deviceSn = deviceSn,
        _repo = repo,
        _comm = comm,
        _onChanged = onChanged;

  DeviceSlice<CalendarSnapshot> get slice => _slice;

  bool get _dirty =>
      _modeOverride != null ||
      _rangeOverride != null ||
      _listOverrides.isNotEmpty;

  CalendarSnapshot? _snapshotOrNull() {
    final base = _base;
    if (base == null) return null;

    if (_modeOverride == null &&
        _rangeOverride == null &&
        _listOverrides.isEmpty) {
      return base;
    }

    final merged = Map<CalendarMode, List<SchedulePoint>>.from(base.lists);
    _listOverrides.forEach((mode, points) {
      merged[mode] = List<SchedulePoint>.unmodifiable(points);
    });

    return base.copyWith(
      mode: _modeOverride ?? base.mode,
      range: _rangeOverride ?? base.range,
      lists: merged,
    );
  }

  void _emit() {
    final snap = _snapshotOrNull();

    if (snap == null) {
      if (_loadError != null) {
        _slice = DeviceSlice<CalendarSnapshot>.error(
          data: CalendarSnapshot.empty(_modeHint),
          error: _loadError!,
        );
      } else if (_watchStarted) {
        _slice = const DeviceSlice<CalendarSnapshot>.loading();
      } else {
        _slice = const DeviceSlice<CalendarSnapshot>.idle();
      }
      _onChanged();
      return;
    }

    if (_savingKind != null) {
      _slice = DeviceSlice<CalendarSnapshot>.saving(
        data: snap,
        dirty: _dirty,
      );
    } else {
      _slice = DeviceSlice<CalendarSnapshot>.ready(
        data: snap,
        error: _flash,
        dirty: _dirty,
      );
    }

    if (!_stream.isClosed) {
      _stream.add(snap);
    }
    _onChanged();
  }

  Future<void> start() async {
    if (_disposed || _watchStarted) return;
    _watchStarted = true;

    _sub = _repo.watchSnapshot().listen(
      (remote) {
        _applyReported(remote: remote);
      },
      onError: (_) {
        if (_base == null) {
          _loadError = 'Failed to read schedule';
        } else {
          _flash = 'Failed to read schedule';
        }
        _emit();
      },
      cancelOnError: false,
    );

    _emit();
  }

  @override
  CalendarSnapshot? get current => _snapshotOrNull();

  @override
  Stream<CalendarSnapshot> watch() {
    return Stream<CalendarSnapshot>.multi((controller) {
      final cur = current;
      if (cur != null) {
        controller.add(cur);
      }

      final sub = _stream.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<CalendarSnapshot> get({bool force = false}) async {
    await start();

    return _serial.run(() async {
      final shouldTrackComm = force || _base == null;
      String? commReqId;
      if (shouldTrackComm) {
        commReqId = newReqId();
        _comm.start(reqId: commReqId, deviceSn: _deviceSn);
      }

      if (_base == null) {
        _loadError = null;
        _emit();
      }

      try {
        final remote = await _repo.fetchAll(forceGet: force);
        _applyReported(remote: remote);

        if (commReqId != null) {
          _comm.complete(commReqId);
        }
      } catch (e) {
        if (commReqId != null) {
          _comm.fail(commReqId, 'Refresh failed');
        }

        final msg =
            e is TimeoutException ? (e.message ?? 'Timeout') : e.toString();

        if (_base == null) {
          _loadError = msg;
        } else {
          _flash = msg;
        }
        _emit();
      }

      final snap = current;
      if (snap == null) {
        throw StateError('Schedule state is not ready');
      }
      return snap;
    });
  }

  @override
  Future<void> commandSetMode(CalendarMode mode) {
    if (_base == null) return Future<void>.value();

    final effectiveMode = (_modeOverride ?? _base!.mode);
    if (mode == effectiveMode) return Future<void>.value();

    if (_savingKind != null) {
      if (_savingKind == _ScheduleSavingKind.mode) {
        return _runModeOp(mode, serialized: false);
      }

      _modeOverride = mode;
      _queued = _queued.withMode(mode);
      _flash = null;
      _emit();
      return Future<void>.value();
    }

    return _runModeOp(mode, serialized: true);
  }

  Future<void> _runModeOp(CalendarMode next, {required bool serialized}) {
    final reqId = newReqId();
    _comm.start(reqId: reqId, deviceSn: _deviceSn);

    _modeOverride = next;
    _savingKind = _ScheduleSavingKind.mode;
    _queued = _queued.clearMode();
    _flash = null;
    _emit();

    final runner = serialized ? _ops.run : _ops.runUnserialized;
    return runner(
      reqId: reqId,
      op: () => _repo.setMode(next, reqId: reqId),
      timeoutReason: 'Schedule mode ACK timeout',
      errorReason: 'Failed to set schedule mode',
      timeoutCommMessage: 'Operation timed out',
      errorCommMessage: (e) => 'Failed to set mode: $e',
      onSuccess: () {
        final base = _base;
        if (base == null) return;

        final newBase = base.copyWith(mode: next);
        _rebaseOnNewBase(newBase);
        _savingKind = null;
        _flash = null;
        _emit();
      },
      onTimeout: _onTimeout,
      onError: (_) => _onFailed('Failed to set mode'),
      onFinally: _flushQueuedIfAny,
    );
  }

  @override
  void patchRange(ScheduleRange range) {
    final base = _base;
    if (base == null) return;

    final normalized = range.normalized();
    if (normalized == base.range) {
      _rangeOverride = null;
    } else {
      _rangeOverride = normalized;
    }

    _flash = null;
    _emit();
  }

  @override
  void patchList(CalendarMode mode, List<SchedulePoint> points) {
    final base = _base;
    if (base == null) return;

    final normalized = _sortedDedup(points);
    final nextOverrides =
        Map<CalendarMode, List<SchedulePoint>>.from(_listOverrides);

    final baseList = base.pointsFor(mode);
    if (_listEq.equals(baseList, normalized)) {
      nextOverrides.remove(mode);
    } else {
      nextOverrides[mode] = normalized;
    }

    _listOverrides =
        Map<CalendarMode, List<SchedulePoint>>.unmodifiable(nextOverrides);
    _flash = null;
    _emit();
  }

  @override
  void patchPoint(int index, SchedulePoint point) {
    final snap = _snapshotOrNull();
    if (snap == null) return;

    final mode = snap.mode;
    final current = List<SchedulePoint>.from(snap.pointsFor(mode));
    if (index < 0 || index >= current.length) return;

    current[index] = point;
    patchList(mode, current);
  }

  @override
  void removePoint(int index) {
    final snap = _snapshotOrNull();
    if (snap == null) return;

    final mode = snap.mode;
    final current = List<SchedulePoint>.from(snap.pointsFor(mode));
    if (index < 0 || index >= current.length) return;

    current.removeAt(index);
    patchList(mode, current);
  }

  @override
  void addPoint([SchedulePoint? point, int stepMinutes = 15]) {
    final snap = _snapshotOrNull();
    if (snap == null) return;

    final mode = snap.mode;
    final current = List<SchedulePoint>.from(snap.pointsFor(mode));
    final nextPoint = point ?? _makeDefaultPoint(current, mode, stepMinutes);

    current.add(nextPoint);
    patchList(mode, current);
  }

  @override
  Future<void> save() {
    final desired = _snapshotOrNull();
    if (desired == null) return Future<void>.value();
    if (!_dirty) return Future<void>.value();

    if (_savingKind != null) {
      _queued = _queued.withSaveAll();
      _flash = null;
      _emit();
      return Future<void>.value();
    }

    final reqId = newReqId();
    _comm.start(reqId: reqId, deviceSn: _deviceSn);

    _savingKind = _ScheduleSavingKind.saveAll;
    _queued = _queued.clearSaveAll();
    _flash = null;
    _emit();

    return _ops.run(
      reqId: reqId,
      op: () => _repo.saveAll(desired, reqId: reqId),
      timeoutReason: 'Schedule saveAll ACK timeout',
      errorReason: 'Failed to save schedule',
      timeoutCommMessage: 'Operation timed out',
      errorCommMessage: (e) => 'Failed to save schedule: $e',
      onSuccess: () {
        _rebaseOnNewBase(desired);
        _savingKind = null;
        _flash = null;
        _emit();
      },
      onTimeout: _onTimeout,
      onError: (_) => _onFailed('Failed to save schedule'),
      onFinally: _flushQueuedIfAny,
    );
  }

  @override
  void discardLocalChanges() {
    _modeOverride = null;
    _listOverrides = const <CalendarMode, List<SchedulePoint>>{};
    _rangeOverride = null;
    _flash = null;
    _emit();
  }

  void _applyReported({required CalendarSnapshot remote}) {
    _rebaseOnNewBase(remote);
    _emit();
  }

  void _rebaseOnNewBase(CalendarSnapshot newBase) {
    _base = newBase;
    _modeHint = newBase.mode;
    _loadError = null;

    if (_modeOverride != null && _modeOverride == newBase.mode) {
      _modeOverride = null;
    }

    if (_rangeOverride != null && _rangeOverride == newBase.range) {
      _rangeOverride = null;
    }

    final nextListOverrides = <CalendarMode, List<SchedulePoint>>{};
    _listOverrides.forEach((mode, points) {
      final baseList = newBase.pointsFor(mode);
      if (!_listEq.equals(baseList, points)) {
        nextListOverrides[mode] = points;
      }
    });
    _listOverrides =
        Map<CalendarMode, List<SchedulePoint>>.unmodifiable(nextListOverrides);
  }

  void _flushQueuedIfAny() {
    if (_savingKind != null) return;

    if (_queued.saveAll) {
      _queued = _queued.clearSaveAll();
      _emit();
      if (_dirty) {
        unawaited(save());
      }
      return;
    }

    final mode = _queued.mode;
    if (mode != null) {
      _queued = _queued.clearMode();
      _emit();

      final base = _base;
      if (base != null && mode != base.mode) {
        unawaited(commandSetMode(mode));
      }
    }
  }

  void _onTimeout() {
    _savingKind = null;
    _flash = 'Operation timed out';
    _emit();
  }

  void _onFailed(String msg) {
    _savingKind = null;
    _flash = msg;
    _emit();
  }

  SchedulePoint _makeDefaultPoint(
    List<SchedulePoint> current,
    CalendarMode mode,
    int stepMinutes,
  ) {
    final now = TimeOfDay.now();
    final time = _nextFreeTime(current, now, stepMinutes);

    final last = current.isNotEmpty ? _normalizePoint(current.last) : null;

    final daysMask = mode == CalendarMode.weekly
        ? (last?.daysMask ?? WeekdayMask.all)
        : WeekdayMask.all;
    final temp = last?.temp ?? 21.0;

    return SchedulePoint(time: time, daysMask: daysMask, temp: temp);
  }

  SchedulePoint _normalizePoint(SchedulePoint point) {
    final hour = point.time.hour.clamp(0, 23);
    final minute = point.time.minute.clamp(0, 59);
    final daysMask = point.daysMask & WeekdayMask.all;

    return SchedulePoint(
      time: TimeOfDay(hour: hour, minute: minute),
      daysMask: daysMask,
      temp: point.temp,
    );
  }

  List<SchedulePoint> _sortedDedup(List<SchedulePoint> points) {
    final out = points.map(_normalizePoint).toList(growable: false);

    out.sort((a, b) {
      final at = a.time.hour * 60 + a.time.minute;
      final bt = b.time.hour * 60 + b.time.minute;
      if (at != bt) return at.compareTo(bt);

      if (a.daysMask != b.daysMask) return a.daysMask.compareTo(b.daysMask);
      return a.temp.compareTo(b.temp);
    });

    final result = <SchedulePoint>[];
    for (final point in out) {
      if (result.isEmpty) {
        result.add(point);
        continue;
      }

      final prev = result.last;
      final sameKey = prev.time.hour == point.time.hour &&
          prev.time.minute == point.time.minute &&
          prev.daysMask == point.daysMask;

      if (sameKey) {
        result[result.length - 1] = point;
      } else {
        result.add(point);
      }
    }

    return List<SchedulePoint>.unmodifiable(result);
  }

  TimeOfDay _nextFreeTime(
    List<SchedulePoint> points,
    TimeOfDay start,
    int stepMinutes,
  ) {
    final used = <int>{};
    for (final point in points) {
      used.add(point.time.hour * 60 + point.time.minute);
    }

    final startMinutes = start.hour * 60 + start.minute;
    final candidate =
        ((startMinutes + stepMinutes - 1) ~/ stepMinutes) * stepMinutes;

    for (var i = 0; i < 1440 ~/ stepMinutes; i++) {
      final minuteOfDay = (candidate + i * stepMinutes) % 1440;
      if (!used.contains(minuteOfDay)) {
        return TimeOfDay(
          hour: minuteOfDay ~/ 60,
          minute: minuteOfDay % 60,
        );
      }
    }

    return start;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    try {
      await _sub?.cancel();
    } catch (_) {}

    try {
      await _stream.close();
    } catch (_) {}
  }
}

enum _ScheduleSavingKind { mode, saveAll }

class _ScheduleQueued {
  final CalendarMode? mode;
  final bool saveAll;

  const _ScheduleQueued({
    this.mode,
    this.saveAll = false,
  });

  _ScheduleQueued withMode(CalendarMode next) =>
      _ScheduleQueued(mode: next, saveAll: saveAll);

  _ScheduleQueued withSaveAll() => _ScheduleQueued(mode: mode, saveAll: true);

  _ScheduleQueued clearMode() => _ScheduleQueued(mode: null, saveAll: saveAll);

  _ScheduleQueued clearSaveAll() => _ScheduleQueued(mode: mode, saveAll: false);
}
