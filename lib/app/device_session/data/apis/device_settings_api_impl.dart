import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/services/mqtt_op_runner.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/serial_executor.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

class DeviceSettingsApiImpl implements DeviceSettingsApi {
  final String _deviceSn;
  final SettingsRepository _repo;
  final MqttCommCubit _comm;
  final VoidCallback _onChanged;

  late final SerialExecutor _serial = SerialExecutor();
  late final MqttOpRunner _ops =
      MqttOpRunner(deviceSn: _deviceSn, serial: _serial, comm: _comm);

  final StreamController<SettingsSnapshot> _stream =
      StreamController<SettingsSnapshot>.broadcast();

  StreamSubscription<SettingsSnapshot>? _sub;
  bool _watchStarted = false;
  bool _disposed = false;

  SettingsSnapshot? _base;
  Map<String, Object?> _overrides = const <String, Object?>{};

  bool _saving = false;
  bool _queuedSaveAll = false;

  String? _flash;
  String? _loadError;

  DeviceSlice<SettingsSnapshot> _slice =
      const DeviceSlice<SettingsSnapshot>.idle();

  static const _eq = DeepCollectionEquality();

  DeviceSettingsApiImpl({
    required String deviceSn,
    required SettingsRepository repo,
    required MqttCommCubit comm,
    required VoidCallback onChanged,
  })  : _deviceSn = deviceSn,
        _repo = repo,
        _comm = comm,
        _onChanged = onChanged;

  DeviceSlice<SettingsSnapshot> get slice => _slice;

  @override
  late final DeviceSettingsDisplayApi display =
      _SettingsDisplayApi(onPatch: patch);
  @override
  late final DeviceSettingsUpdateApi update =
      _SettingsUpdateApi(onPatch: patch);
  @override
  late final DeviceSettingsTimeApi time = _SettingsTimeApi(onPatch: patch);

  bool get _dirty => _overrides.isNotEmpty;

  SettingsSnapshot? _snapshotOrNull() {
    final base = _base;
    if (base == null) return null;

    var next = base;
    _overrides.forEach((path, value) {
      next = next.copyWithValue(path, value);
    });
    return next;
  }

  void _emit() {
    final snap = _snapshotOrNull();

    if (snap == null) {
      if (_loadError != null) {
        _slice = DeviceSlice<SettingsSnapshot>.error(error: _loadError!);
      } else if (_watchStarted) {
        _slice = const DeviceSlice<SettingsSnapshot>.loading();
      } else {
        _slice = const DeviceSlice<SettingsSnapshot>.idle();
      }
      _onChanged();
      return;
    }

    if (_saving) {
      _slice = DeviceSlice<SettingsSnapshot>.saving(
        data: snap,
        dirty: _dirty,
      );
    } else {
      _slice = DeviceSlice<SettingsSnapshot>.ready(
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
          _loadError = 'Failed to read settings';
        } else {
          _flash = 'Failed to read settings';
        }
        _emit();
      },
      cancelOnError: false,
    );

    _emit();
  }

  @override
  SettingsSnapshot? get current => _snapshotOrNull();

  @override
  Stream<SettingsSnapshot> watch() {
    return Stream<SettingsSnapshot>.multi((controller) {
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
  Future<SettingsSnapshot> get({bool force = false}) async {
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
        throw StateError('Settings state is not ready');
      }
      return snap;
    });
  }

  @override
  void patch(String path, Object? value) {
    final base = _base;
    if (base == null) return;

    final next = Map<String, Object?>.from(_overrides);
    final baseValue = _getAtPath(base.raw, path);

    final same = (baseValue is num && value is num)
        ? baseValue.toDouble() == value.toDouble()
        : _eq.equals(baseValue, value);

    if (same) {
      next.remove(path);
    } else {
      next[path] = value;
    }

    _overrides = Map<String, Object?>.unmodifiable(next);
    _flash = null;
    _emit();
  }

  @override
  void patchAll(Map<String, Object?> values) {
    values.forEach((path, value) {
      patch(path, value);
    });
  }

  @override
  Future<void> save() {
    final desired = _snapshotOrNull();
    if (desired == null) return Future<void>.value();
    if (!_dirty) return Future<void>.value();
    final patch = _buildNestedPatch(_overrides);

    if (_saving) {
      _queuedSaveAll = true;
      _flash = null;
      _emit();
      return Future<void>.value();
    }

    final reqId = newReqId();
    _comm.start(reqId: reqId, deviceSn: _deviceSn);

    _saving = true;
    _queuedSaveAll = false;
    _flash = null;
    _emit();

    return _ops.run(
      reqId: reqId,
      op: () => _repo.patch(patch, reqId: reqId),
      timeoutReason: 'Settings ACK timeout',
      errorReason: 'Failed to save settings',
      timeoutCommMessage: 'Operation timed out',
      errorCommMessage: (e) => 'Failed to save settings: $e',
      onSuccess: () {
        _base = desired;
        _overrides = const <String, Object?>{};
        _saving = false;
        _flash = null;
        _loadError = null;
        _emit();
      },
      onTimeout: () {
        _saving = false;
        _flash = 'Operation timed out';
        _emit();
      },
      onError: (_) {
        _saving = false;
        _flash = 'Failed to save settings';
        _emit();
      },
      onFinally: _flushQueuedIfAny,
    );
  }

  @override
  void discardLocalChanges() {
    _overrides = const <String, Object?>{};
    _flash = null;
    _emit();
  }

  void _applyReported({required SettingsSnapshot remote}) {
    _loadError = null;

    if (_overrides.isEmpty) {
      _base = remote;
      _emit();
      return;
    }

    final nextOverrides = <String, Object?>{};
    _overrides.forEach((path, value) {
      final baseValue = _getAtPath(remote.raw, path);
      if (!_eq.equals(baseValue, value)) {
        nextOverrides[path] = value;
      }
    });

    _base = remote;
    _overrides = Map<String, Object?>.unmodifiable(nextOverrides);
    _emit();
  }

  void _flushQueuedIfAny() {
    if (_saving) return;
    if (!_queuedSaveAll) return;

    _queuedSaveAll = false;
    _emit();

    if (_dirty) {
      unawaited(save());
    }
  }

  static Object? _getAtPath(Map<String, dynamic> root, String path) {
    final parts = path.split('.');
    if (parts.isEmpty) return null;

    dynamic cur = root;
    for (final part in parts) {
      if (cur is! Map<String, dynamic>) return null;
      cur = cur[part];
    }
    return cur;
  }

  static Map<String, dynamic> _buildNestedPatch(Map<String, Object?> values) {
    final out = <String, dynamic>{};
    values.forEach((path, value) {
      final parts = path.split('.');
      if (parts.isEmpty) return;

      Map<String, dynamic> cur = out;
      for (var i = 0; i < parts.length; i++) {
        final key = parts[i];
        final isLast = i == parts.length - 1;
        if (isLast) {
          cur[key] = value;
          continue;
        }

        final next = cur[key];
        if (next is Map<String, dynamic>) {
          cur = next;
          continue;
        }

        final created = <String, dynamic>{};
        cur[key] = created;
        cur = created;
      }
    });
    return out;
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

class _SettingsDisplayApi implements DeviceSettingsDisplayApi {
  final void Function(String path, Object? value) onPatch;

  _SettingsDisplayApi({required this.onPatch});

  @override
  void setActiveBrightness(int value) =>
      onPatch('display.activeBrightness', value);

  @override
  void setIdleBrightness(int value) => onPatch('display.idleBrightness', value);

  @override
  void setIdleTime(int value) => onPatch('display.idleTime', value);

  @override
  void setDimOnIdle(bool value) => onPatch('display.dimOnIdle', value);

  @override
  void setLanguage(String value) => onPatch('display.language', value);
}

class _SettingsUpdateApi implements DeviceSettingsUpdateApi {
  final void Function(String path, Object? value) onPatch;

  _SettingsUpdateApi({required this.onPatch});

  @override
  void setAutoUpdateEnabled(bool value) =>
      onPatch('update.autoUpdateEnabled', value);

  @override
  void setUpdateAtMidnight(bool value) =>
      onPatch('update.updateAtMidnight', value);

  @override
  void setCheckIntervalMin(int value) =>
      onPatch('update.checkIntervalMin', value);
}

class _SettingsTimeApi implements DeviceSettingsTimeApi {
  final void Function(String path, Object? value) onPatch;

  _SettingsTimeApi({required this.onPatch});

  @override
  void setAuto(bool value) => onPatch('time.auto', value);

  @override
  void setTimeZone(int value) => onPatch('time.timeZone', value);
}
