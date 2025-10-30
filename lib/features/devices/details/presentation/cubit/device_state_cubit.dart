import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/enable_rt_stream_usecase.dart';
// ===== domain use cases =====
import '../../domain/usecases/subscribe_device_stream.dart';

/// Simple state holding a key-value map with helper `valueOf`.
class DeviceStateState {
  final Map<String, dynamic> data;

  const DeviceStateState(this.data);

  factory DeviceStateState.initial() => const DeviceStateState({});

  DeviceStateState merge(Map<String, dynamic> diff) => DeviceStateState({...data, ...diff});

  dynamic valueOf(String key) => data[key];
}

class DeviceStateCubit extends Cubit<DeviceStateState> {
  DeviceStateCubit({
    required SubscribeDeviceStreamUseCase subscribeUc,
    required UnsubscribeDeviceStreamUseCase unsubscribeUc,
    required GetDeviceStreamUseCase getStreamUc,
    required EnableRtStreamUseCase enableRtUc,
    required DisableRtStreamUseCase disableRtUc,
  })  : _subscribeUc = subscribeUc,
        _unsubscribeUc = unsubscribeUc,
        _getStreamUc = getStreamUc,
        _enableRtUc = enableRtUc,
        _disableRtUc = disableRtUc,
        super(DeviceStateState.initial());

  final SubscribeDeviceStreamUseCase _subscribeUc;
  final UnsubscribeDeviceStreamUseCase _unsubscribeUc;
  final GetDeviceStreamUseCase _getStreamUc;
  final EnableRtStreamUseCase _enableRtUc;
  final DisableRtStreamUseCase _disableRtUc;

  StreamSubscription<Map<String, dynamic>>? _sub;
  String? _deviceId;

  /// Bind UI to a specific device: enable RT, subscribe, and start merging incoming telemetry.
  Future<void> bindDevice(String deviceId) async {
    if (_deviceId == deviceId) return;

    // Unbind previous device (with graceful RT disable)
    await _unbindInternal();

    _deviceId = deviceId;

    // 1) Ask device to push telemetry at 1Hz while this screen is active
    try {
      await _enableRtUc(deviceId, interval: const Duration(seconds: 1));
    } catch (_) {
      // Non-fatal: we still subscribe and show last-known updates
    }

    // 2) Subscribe to MQTT topics for this device
    await _subscribeUc(deviceId);

    // 3) Start listening to domain stream and merge into state
    _sub = _getStreamUc(deviceId).listen(
      (diff) => emit(state.merge(diff)),
      onError: (_) {}, // keep UI alive on transient errors
      cancelOnError: false,
    );
  }

  /// Explicit unbind (optional, called on presenter's dispose). Also called internally.
  Future<void> unbind() => _unbindInternal();

  Future<void> _unbindInternal() async {
    await _sub?.cancel();
    _sub = null;

    if (_deviceId != null) {
      // Revert device telemetry rate to default (e.g., 5 minutes)
      try {
        await _disableRtUc(_deviceId!);
      } catch (_) {
        // ignore
      }
      await _unsubscribeUc(_deviceId!);
      _deviceId = null;
    }
  }

  @override
  Future<void> close() async {
    await _unbindInternal();
    return super.close();
  }
}
