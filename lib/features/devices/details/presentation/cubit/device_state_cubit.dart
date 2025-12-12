import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/logging/osh_crash_reporter.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/disable_rt_stream.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/enable_rt_stream.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/subscribe_telemetry.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/unsubscribe_telemetry.dart';
import 'package:oshmobile/features/devices/details/domain/usecases/watch_telemetry.dart';

enum DeviceLiveStatus { idle, connecting, live, degraded }

class DeviceStateState {
  final String? deviceId;
  final DeviceLiveStatus status;
  final DateTime? lastUpdate;
  final Map<String, dynamic> data; // alias -> value

  const DeviceStateState({
    required this.data,
    this.deviceId,
    this.status = DeviceLiveStatus.idle,
    this.lastUpdate,
  });

  factory DeviceStateState.initial() => const DeviceStateState(data: {});

  dynamic getDynamic(Signal<dynamic> s) {
    return data[s.alias];
  }

  T? get<T>(Signal<T> s) {
    final v = data[s.alias];
    return v is T ? v : null;
  }

  DeviceStateState copyWith({
    String? deviceId,
    DeviceLiveStatus? status,
    DateTime? lastUpdate,
    Map<String, dynamic>? data,
  }) =>
      DeviceStateState(
        data: data ?? this.data,
        deviceId: deviceId ?? this.deviceId,
        status: status ?? this.status,
        lastUpdate: lastUpdate ?? this.lastUpdate,
      );

  DeviceStateState merge(Map<String, dynamic> diff) {
    if (diff.isEmpty) return this;
    var changed = false;
    final next = Map<String, dynamic>.from(data);
    diff.forEach((k, v) {
      if (next[k] != v) {
        next[k] = v;
        changed = true;
      }
    });
    return changed ? copyWith(data: next, lastUpdate: DateTime.now(), status: DeviceLiveStatus.live) : this;
  }
}

class DeviceStateCubit extends Cubit<DeviceStateState> {
  DeviceStateCubit({
    required SubscribeTelemetry subscribe,
    required UnsubscribeTelemetry unsubscribe,
    required WatchTelemetry watch,
    required EnableRtStream enableRt,
    required DisableRtStream disableRt,
    this.rtInterval = const Duration(seconds: 1),
  })  : _subscribe = subscribe,
        _unsubscribe = unsubscribe,
        _watch = watch,
        _enableRt = enableRt,
        _disableRt = disableRt,
        super(DeviceStateState.initial());

  final SubscribeTelemetry _subscribe;
  final UnsubscribeTelemetry _unsubscribe;
  final WatchTelemetry _watch;
  final EnableRtStream _enableRt;
  final DisableRtStream _disableRt;
  final Duration rtInterval; // policy knob

  StreamSubscription<Map<String, dynamic>>? _sub;
  int _bindToken = 0;

  /// Bind to a specific device and start consuming telemetry alias-diffs.
  Future<void> bind(String deviceId) async {
    final token = ++_bindToken;
    await _sub?.cancel();
    emit(DeviceStateState.initial().copyWith(deviceId: deviceId, status: DeviceLiveStatus.connecting));

    // 1) Try to enable RT (non-fatal)
    try {
      await _enableRt(deviceId, interval: rtInterval);
    } catch (e, st) {
      OshCrashReporter.logNonFatal(e, st, reason: "Failed to enable RT stream", context: {"deviceId":deviceId});
    }

    // 2) Subscribe and watch
    try {
      await _subscribe(deviceId);
    } catch (e, st) {
      OshCrashReporter.logNonFatal(e, st, reason: "Failed to subscribe", context: {"deviceId":deviceId});
    }
    _sub = _watch(deviceId).listen(
      (diff) {
        if (token != _bindToken) return;
        emit(state.merge(diff));
      },
      onError: (e) {
        if (token != _bindToken) return;
        OshCrashReporter.log("DeviceStateState: onError: error: $e");
        emit(state.copyWith(status: DeviceLiveStatus.degraded));
      },
      cancelOnError: false,
    );
  }

  /// Unbind and stop consuming telemetry.
  Future<void> unbind() async {
    final did = state.deviceId;
    _bindToken++;
    await _sub?.cancel();
    _sub = null;

    if (did != null) {
      try {
        await _disableRt(did);
      } catch (_) {}
      try {
        await _unsubscribe(did);
      } catch (_) {}
    }
    emit(DeviceStateState.initial());
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
