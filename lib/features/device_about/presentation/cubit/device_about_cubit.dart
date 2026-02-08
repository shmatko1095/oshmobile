import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/device_about/domain/usecases/watch_device_about_stream.dart';

part 'device_about_state.dart';

class DeviceAboutCubit extends Cubit<DeviceAboutState> {
  final WatchDeviceAboutStream _watch;

  StreamSubscription<Map<String, dynamic>>? _sub;

  DeviceAboutCubit({
    required WatchDeviceAboutStream watch,
  })  : _watch = watch,
        super(const DeviceAboutLoading());

  void start() {
    if (isClosed) return;

    _sub?.cancel();
    _sub = _watch().listen(
      (data) {
        emit(DeviceAboutReady(data: data, receivedAt: DateTime.now()));
      },
      onError: (e) {
        emit(DeviceAboutError('Failed to read device state', last: state.maybeData));
      },
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  Future<void> close() async {
    await stop();
    return super.close();
  }
}
