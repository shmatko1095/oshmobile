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

class DeviceSettingsCubit extends Cubit<DeviceSettingsState> {
  final FetchSettingsAll _fetchAll;
  final SaveSettingsAll _saveAll;
  final WatchSettingsStream _watchStream;
  final MqttCommCubit _comm;

  /// ACK wait timeout for each save operation.
  final Duration ackTimeout;

  String _deviceSn = '';
  int _bindToken = 0;

  StreamSubscription<MapEntry<String?, SettingsSnapshot>>? _sub;
  final Map<String, Timer> _pendingTimers = {};

  DeviceSettingsCubit({
    required FetchSettingsAll fetchAll,
    required SaveSettingsAll saveAll,
    required WatchSettingsStream watchStream,
    required MqttCommCubit comm,
    Duration ackTimeoutOverride = const Duration(seconds: 8),
  })  : _fetchAll = fetchAll,
        _saveAll = saveAll,
        _watchStream = watchStream,
        _comm = comm,
        ackTimeout = ackTimeoutOverride,
        super(const DeviceSettingsLoading());

  /// Rebind to the last known deviceSn.
  Future<void> rebind() async {
    if (_deviceSn.isEmpty) return;
    await bind(_deviceSn);
  }

  /// Bind this cubit to a device.
  ///
  /// - Subscribes to reported settings stream.
  /// - Fetches initial snapshot.
  /// - Uses MqttCommCubit to track in-flight "load settings" operation.
  Future<void> bind(String deviceSn) async {
    await _sub?.cancel();
    _cancelAllTimers();

    final prevDeviceSn = _deviceSn;
    _deviceSn = deviceSn;
    final token = ++_bindToken;

    final reqId = newReqId();
    _comm.start(reqId: reqId, deviceSn: deviceSn);

    // Reset transient state when changing device.
    final current = state;
    if (current is DeviceSettingsReady && prevDeviceSn.isNotEmpty) {
      _comm.dropForDevice(prevDeviceSn);
      emit(current.copyWith(
        dirty: false,
        saving: false,
        flash: null,
        pendingReqId: null,
      ));
    }

    emit(const DeviceSettingsLoading());

    _sub = _watchStream(deviceSn).listen((entry) {
      if (token != _bindToken) return;
      _onReported(entry.key, entry.value);
    });

    try {
      final snap = await _fetchAll(deviceSn);
      if (token != _bindToken) return;
      _comm.complete(reqId);
      emit(DeviceSettingsReady(snapshot: snap));
    } catch (e, st) {
      if (token != _bindToken) return;
      OshCrashReporter.logNonFatal(e, st, reason: "Failed to load settings", context: {"deviceSn":deviceSn});
      _comm.fail(reqId, 'Failed to load settings: $e');
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

    // Correlated ACK for our last save.
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

    // Spontaneous update or unrelated reqId.
    if (st.dirty || st.saving) {
      // User is editing; adopt remote snapshot but keep dirty/saving flags
      // so UI remains optimistic.
      emit(st.copyWith(snapshot: remote));
    } else {
      emit(st.copyWith(
        snapshot: remote,
        dirty: false,
        saving: false,
      ));
    }
  }

  /// Update single field optimistically.
  ///
  /// [fieldId] is a path like "display.activeBrightness".
  void changeValue(String fieldId, Object? value) {
    final st = state;
    if (st is! DeviceSettingsReady) return;

    final nextSnap = st.snapshot.copyWithValue(fieldId, value);
    emit(st.copyWith(
      snapshot: nextSnap,
      dirty: true,
      flash: null,
    ));
  }

  /// Persist current snapshot to device.
  ///
  /// Generates reqId, registers it with MqttCommCubit and waits for reported ACK.
  Future<void> persist() async {
    final st = state;
    if (st is! DeviceSettingsReady) return;
    if (!st.dirty || st.saving) return;

    final reqId = newReqId();
    _comm.start(reqId: reqId, deviceSn: _deviceSn);

    emit(st.copyWith(
      saving: true,
      flash: null,
      pendingReqId: reqId,
    ));

    try {
      await _saveAll(_deviceSn, st.snapshot, reqId: reqId);
      _scheduleTimeout(reqId);
    } catch (e, stack) {
      OshCrashReporter.logNonFatal(e, stack, reason: "Failed to save settings", context: {"deviceSn":_deviceSn});
      _comm.fail(reqId, 'Failed to save settings: $e');
      emit(st.copyWith(
        saving: false,
        flash: 'Failed to save settings',
        pendingReqId: null,
      ));
    }
  }

  /// Discard local unsaved changes and revert to last snapshot (no reload).
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

    OshCrashReporter.log("Settings operation timed out, deviceSn: $_deviceSn");
    emit(st.copyWith(
      saving: false,
      // keep dirty = true to allow user to retry
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
    _cancelAllTimers();
    return super.close();
  }
}
