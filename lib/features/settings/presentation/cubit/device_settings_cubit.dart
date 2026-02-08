import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/common/services/mqtt_op_runner.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/core/utils/serial_executor.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/usecases/fetch_settings_all.dart';
import 'package:oshmobile/features/settings/domain/usecases/save_settings_all.dart';
import 'package:oshmobile/features/settings/domain/usecases/watch_settings_stream.dart';

part 'device_settings_state.dart';

/// Device-scoped settings cubit: one instance per deviceSn.
///
/// Principles:
/// - ACK/timeout handled ONLY in repository/usecase.
/// - Cubit maintains base/draft (base + overrides).
/// - Network ops serialized to avoid overlap.
/// - Latest-wins save intent while saving lives in state (queued).
class DeviceSettingsCubit extends Cubit<DeviceSettingsState> {
  final String deviceSn;

  final FetchSettingsAll _fetchAll;
  final SaveSettingsAll _saveAll;
  final WatchSettingsStream _watchStream;
  final MqttCommCubit _comm;

  late final SerialExecutor _serial = SerialExecutor();
  late final MqttOpRunner _ops = MqttOpRunner(deviceSn: deviceSn, serial: _serial, comm: _comm);

  StreamSubscription<SettingsSnapshot>? _sub;
  bool _watchStarted = false;

  static const _eq = DeepCollectionEquality();

  DeviceSettingsCubit({
    required this.deviceSn,
    required FetchSettingsAll fetchAll,
    required SaveSettingsAll saveAll,
    required WatchSettingsStream watchStream,
    required MqttCommCubit comm,
  })  : _fetchAll = fetchAll,
        _saveAll = saveAll,
        _watchStream = watchStream,
        _comm = comm,
        super(const DeviceSettingsLoading());

  /// Call once after creation (from DeviceScope).
  void start() {
    if (_watchStarted) return;
    _watchStarted = true;

    _sub = _watchStream(deviceSn).listen((snap) {
      _applyReported(remote: snap);
    });
  }

  Future<void> refresh({bool forceGet = false}) => _serial.run(() async {
        final shouldTrackComm = forceGet || state is! DeviceSettingsReady;
        String? commReqId;
        if (shouldTrackComm) {
          commReqId = newReqId();
          _comm.start(reqId: commReqId, deviceSn: deviceSn);
        }

        final prev = state;
        if (prev is! DeviceSettingsReady) {
          emit(const DeviceSettingsLoading());
        }

        try {
          final remote = await _fetchAll(deviceSn, forceGet: forceGet);
          if (isClosed) return;

          final st = _readyOrNull();
          if (st != null) {
            emit(_rebaseOnNewBase(st, remote));
          } else {
            emit(DeviceSettingsReady(base: remote));
          }

          if (commReqId != null) _comm.complete(commReqId);
        } catch (e) {
          if (commReqId != null) _comm.fail(commReqId, 'Refresh failed');
          rethrow;
        }
      });

  void changeValue(String fieldId, Object? value) {
    final st = _readyOrNull();
    if (st == null) return;

    final next = Map<String, Object?>.from(st.overrides);

    final baseVal = _getAtPath(st.base.raw, fieldId);

    final same = (baseVal is num && value is num) ? baseVal.toDouble() == value.toDouble() : _eq.equals(baseVal, value);

    if (same) {
      next.remove(fieldId);
    } else {
      next[fieldId] = value;
    }

    emit(st.copyWith(overrides: Map.unmodifiable(next), flash: null));
  }

  void discardLocalChanges() {
    final st = _readyOrNull();
    if (st == null) return;
    emit(st.copyWith(overrides: const {}, flash: null));
  }

  Future<void> saveAll() {
    final st = _readyOrNull();
    if (st == null) return Future.value();

    if (!st.dirty) return Future.value();

    // Latest-wins: if saving, remember another save request once.
    if (st.saving) {
      emit(st.copyWith(queued: st.queued.withSaveAll(), flash: null));
      return Future.value();
    }

    final reqId = newReqId();
    final desired = st.snapshot;

    _comm.start(reqId: reqId, deviceSn: deviceSn);

    emit(st.copyWith(
      saving: true,
      queued: st.queued.clearSaveAll(),
      flash: null,
    ));

    return _ops.run(
      reqId: reqId,
      op: () => _saveAll(deviceSn, desired, reqId: reqId),
      timeoutReason: 'Settings ACK timeout',
      errorReason: 'Failed to save settings',
      timeoutCommMessage: 'Operation timed out',
      errorCommMessage: (e) => 'Failed to save settings: $e',
      onSuccess: () {
        if (isClosed) return;
        final cur = _readyOrNull();
        if (cur == null) return;

        emit(_rebaseOnNewBase(cur, desired).copyWith(saving: false, flash: null));
      },
      onTimeout: () {
        if (isClosed) return;
        final cur = _readyOrNull();
        if (cur == null) return;

        emit(cur.copyWith(saving: false, flash: 'Operation timed out'));
      },
      onError: (_) {
        if (isClosed) return;
        final cur = _readyOrNull();
        if (cur == null) return;

        emit(cur.copyWith(saving: false, flash: 'Failed to save settings'));
      },
      onFinally: _flushQueuedIfAny,
    );
  }

  void _applyReported({required SettingsSnapshot remote}) {
    if (isClosed) return;

    final st = _readyOrNull();
    if (st == null) {
      emit(DeviceSettingsReady(base: remote));
      return;
    }

    emit(_rebaseOnNewBase(st, remote));
  }

  void _flushQueuedIfAny() {
    if (isClosed) return;

    final st = _readyOrNull();
    if (st == null) return;
    if (st.saving) return;

    final q = st.queued;
    if (q.isEmpty) return;

    if (q.saveAll) {
      emit(st.copyWith(queued: q.clearSaveAll()));
      if (st.dirty) unawaited(saveAll());
    }
  }

  DeviceSettingsReady _rebaseOnNewBase(DeviceSettingsReady st, SettingsSnapshot newBase) {
    if (st.overrides.isEmpty) {
      return st.copyWith(base: newBase);
    }

    final nextOverrides = <String, Object?>{};
    st.overrides.forEach((path, value) {
      final baseVal = _getAtPath(newBase.raw, path);
      if (!_eq.equals(baseVal, value)) {
        nextOverrides[path] = value;
      }
    });

    return st.copyWith(
      base: newBase,
      overrides: Map.unmodifiable(nextOverrides),
    );
  }

  DeviceSettingsReady? _readyOrNull() {
    final st = state;
    return st is DeviceSettingsReady ? st : null;
  }

  static Object? _getAtPath(Map<String, dynamic> root, String path) {
    final parts = path.split('.');
    if (parts.isEmpty) return null;

    dynamic cur = root;
    for (final p in parts) {
      if (cur is! Map<String, dynamic>) return null;
      cur = cur[p];
    }
    return cur;
  }

  @override
  Future<void> close() async {
    try {
      await _sub?.cancel();
    } catch (_) {}
    return super.close();
  }
}
