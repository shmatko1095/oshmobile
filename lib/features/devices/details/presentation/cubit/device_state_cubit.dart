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
  final Map<String, dynamic> data;

  const DeviceStateState({
    required this.data,
    this.deviceId,
    this.status = DeviceLiveStatus.idle,
    this.lastUpdate,
  });

  factory DeviceStateState.initial() => const DeviceStateState(data: {});

  dynamic getDynamic(Signal<dynamic> s) => data[s.alias];

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
    final next = Map<String, dynamic>.from(data);
    var changed = false;

    diff.forEach((k, v) {
      if (next[k] != v) {
        next[k] = v;
        changed = true;
      }
    });

    return changed
        ? copyWith(
            data: next,
            lastUpdate: DateTime.now(),
            status: DeviceLiveStatus.live,
          )
        : this;
  }
}

/// Device-scoped: one instance per deviceSn.
/// Lifecycle is handled by DeviceScope disposal.
class DeviceStateCubit extends Cubit<DeviceStateState> {
  final SubscribeTelemetry _subscribe;
  final UnsubscribeTelemetry _unsubscribe;
  final WatchTelemetry _watch;
  final EnableRtStream _enableRt;
  final DisableRtStream _disableRt;

  final String deviceSn;
  final Duration rtInterval;

  StreamSubscription<Map<String, dynamic>>? _sub;

  DeviceStateCubit({
    required this.deviceSn,
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

  /// Call once after creation (from DeviceScope).
  Future<void> start() async {
    // if (isClosed) return;

    emit(state.copyWith(deviceId: deviceSn, status: DeviceLiveStatus.connecting));

    // Enable RT stream (best-effort).
    try {
      await _enableRt(interval: rtInterval);
    } catch (e, st) {
      unawaited(OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'Failed to enable RT stream',
        context: {'deviceSn': deviceSn},
      ));
    }
    // if (isClosed) return;

    // Subscribe (best-effort).
    try {
      await _subscribe();
    } catch (e, st) {
      unawaited(OshCrashReporter.logNonFatal(
        e,
        st,
        reason: 'Failed to subscribe telemetry',
        context: {'deviceSn': deviceSn},
      ));
    }
    // if (isClosed) return;

    // Watch telemetry stream.
    await _sub?.cancel();
    // if (isClosed) return;

    _sub = _watch().listen(
      (diff) {
        // if (isClosed) return;
        emit(state.merge(diff));
      },
      onError: (e) {
        // if (isClosed) return;
        OshCrashReporter.log('DeviceStateCubit: watch error: $e');
        emit(state.copyWith(status: DeviceLiveStatus.degraded));
      },
      cancelOnError: false,
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;

    // Best-effort cleanup on device dispose.
    try {
      await _disableRt();
    } catch (_) {}
    try {
      await _unsubscribe();
    } catch (_) {}

    return super.close();
  }
}
