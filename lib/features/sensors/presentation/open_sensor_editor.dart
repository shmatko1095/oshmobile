import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/sensors/presentation/models/sensor_editor_entry.dart';
import 'package:oshmobile/features/sensors/presentation/pages/sensor_editor_page.dart';

class SensorEditorNavigator {
  static void openFromHost(
    BuildContext hostContext, {
    required SensorEditorEntry sensor,
  }) {
    if (!hostContext.mounted) return;

    late final DeviceFacade facade;
    late final DeviceSnapshotCubit snapshotCubit;
    try {
      facade = hostContext.read<DeviceFacade>();
      snapshotCubit = hostContext.read<DeviceSnapshotCubit>();
    } catch (_) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: 'Device scope is not available in the current context.',
      );
      return;
    }

    Navigator.of(hostContext).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: OshAnalyticsScreens.sensorEditor),
        builder: (_) => DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: SensorEditorPage(sensor: sensor),
        ),
      ),
    );
  }
}
