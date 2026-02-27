import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';

class DeviceRouteScope {
  const DeviceRouteScope._();

  static Widget provide({
    required DeviceFacade facade,
    required DeviceSnapshotCubit snapshotCubit,
    required Widget child,
  }) {
    return RepositoryProvider<DeviceFacade>.value(
      value: facade,
      child: BlocProvider<DeviceSnapshotCubit>.value(
        value: snapshotCubit,
        child: child,
      ),
    );
  }
}
