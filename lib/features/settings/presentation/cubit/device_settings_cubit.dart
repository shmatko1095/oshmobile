import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/cubits/mqtt/mqtt_comm_cubit.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/utils/req_id.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/usecases/fetch_settings_all.dart';
import 'package:oshmobile/features/settings/domain/usecases/save_settings_all.dart';
import 'package:oshmobile/features/settings/domain/usecases/watch_settings_stream.dart';

part 'device_settings_state.dart';

/// Device-scoped settings cubit: one instance per deviceSn.
class DeviceSettingsCubit extends Cubit<DeviceSettingsState> {
  final String deviceSn;

  final FetchSettingsAll _fetchAll;
  final SaveSettingsAll _saveAll;
  final WatchSettingsStream _watchStream;
  final MqttCommCubit _comm;

  final Duration ackTimeout;

  StreamSubscription<MapEntry<String?, SettingsSnapshot>>? _sub;
  final Map<String, Timer> _pendingTimers = {};

  bool _watchStarted = false;

  DeviceSettingsCubit({
    required this.deviceSn,
    required FetchSettingsAll fetchAll,
    required SaveSettingsAll saveAll,
    required WatchSettingsStream watchStream,
    required MqttCommCubit comm,
    this.ackTimeout = const Duration(seconds: 8),
  })  : _fetchAll = fetchAll,
        _saveAll = saveAll,
        _watchStream = watchStream,
        _comm = comm,
        super(const DeviceSettingsLoading());

  /// Call once after creation (from DeviceScope).
  void start() {
    if (_watchStarted) return;
    _watchStarted = true;

    _sub = _watchStream(deviceSn).listen((entry) {
      _onReported(entry.key, entry.value);
    });
  }

  Future<void> refresh() => _loadInitial();

  Future<void> _loadInitial() async {
    if (isClosed) return;
    emit(const DeviceSettingsLoading());

    try {
      final snap = await _fetchAll(deviceSn);
      if (isClosed) return;
      emit(DeviceSettingsReady(snapshot: snap));
    } catch (e, st) {
      if (isClosed) return;
      OshCrashReporter.logNonFatal(e, st, reason: "Failed to load settings", context: {"deviceSn": deviceSn});
      emit(DeviceSettingsError(e.toString()));
    }
  }

  void _onReported(String? appliedReqId, SettingsSnapshot remote) {
    if (isClosed) return;
    final st = state;
    if (st is! DeviceSettingsReady) {
      emit(DeviceSettingsReady(snapshot: remote));
      return;
    }

    if (st.pendingReqId != null &&
        st.pendingReqId!.isNotEmpty &&
        appliedReqId != null &&
        appliedReqId == st.pendingReqId) {
      _pendingTimers.remove(st.pendingReqId!)?.cancel();
      _comm.complete(st.pendingReqId!);

      emit(st.copyWith(
        snapshot: remote,
        dirty: false,
        saving: false,
        pendingReqId: null,
      ));
      return;
    }

    if (st.dirty || st.saving) {
      emit(st.copyWith(snapshot: remote));
    } else {
      emit(st.copyWith(snapshot: remote, dirty: false, saving: false));
    }
  }

  void changeValue(String fieldId, Object? value) {
    final st = state;
    if (st is! DeviceSettingsReady) return;

    final nextSnap = st.snapshot.copyWithValue(fieldId, value);
    emit(st.copyWith(snapshot: nextSnap, dirty: true, flash: null));
  }

  Future<void> persist() async {
    final st = state;
    if (st is! DeviceSettingsReady) return;
    if (!st.dirty || st.saving) return;

    final reqId = newReqId();
    _comm.start(reqId: reqId, deviceSn: deviceSn);

    emit(st.copyWith(
      saving: true,
      flash: null,
      pendingReqId: reqId,
    ));

    try {
      await _saveAll(deviceSn, st.snapshot, reqId: reqId);
      if (isClosed) return;
      _scheduleTimeout(reqId);
    } catch (e, stack) {
      OshCrashReporter.logNonFatal(e, stack, reason: "Failed to save settings", context: {"deviceSn": deviceSn});
      _comm.fail(reqId, 'Failed to save settings: $e');
      if (isClosed) return;
      emit(st.copyWith(saving: false, flash: 'Failed to save settings', pendingReqId: null));
    }
  }

  void discardLocalChanges() {
    final st = state;
    if (st is! DeviceSettingsReady) return;
    emit(st.copyWith(dirty: false, flash: null));
  }

  void _scheduleTimeout(String reqId) {
    _pendingTimers[reqId]?.cancel();
    _pendingTimers[reqId] = Timer(ackTimeout, () => _onTimeout(reqId));
  }

  void _onTimeout(String reqId) {
    if (isClosed) return;
    final st = state;
    if (st is! DeviceSettingsReady) return;
    if (st.pendingReqId != reqId) return;

    _pendingTimers.remove(reqId)?.cancel();
    _comm.fail(reqId, 'Settings operation timed out');

    emit(st.copyWith(
      saving: false,
      flash: 'Settings operation timed out',
      pendingReqId: null,
    ));
  }

  void _cancelAllTimers() {
    for (final t in _pendingTimers.values) {
      t.cancel();
    }
    _pendingTimers.clear();
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    _cancelAllTimers();

    _comm.dropForDevice(deviceSn);

    return super.close();
  }
}
