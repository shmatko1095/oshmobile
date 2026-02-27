import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';

/// UI-facing reactive wrapper around [DeviceFacade.watch].
class DeviceSnapshotCubit extends Cubit<DeviceSnapshot> {
  final DeviceFacade _facade;
  StreamSubscription<DeviceSnapshot>? _sub;

  DeviceSnapshotCubit({
    required DeviceFacade facade,
  })  : _facade = facade,
        super(facade.current);

  void start() {
    _sub?.cancel();
    _sub = _facade.watch().listen(
      (snapshot) {
        if (!isClosed) emit(snapshot);
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  Future<void> refreshAll({bool force = false}) =>
      _facade.refreshAll(forceGet: force);

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
