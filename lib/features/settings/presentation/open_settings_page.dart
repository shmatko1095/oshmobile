import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';

import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';

import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/settings/presentation/pages/device_settings_page.dart';

class DeviceSettingsNavigator {
  static void openFromHost(BuildContext hostContext, Device device) {
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

    final uiSchema = facade.settingsUiSchema;
    if (uiSchema == null || uiSchema.fieldsByPath.isEmpty) {
      SnackBarUtils.showFail(
        context: hostContext,
        content: 'This device does not expose any settings.',
      );
      return;
    }

    // Ensure settings are actively fetched when opening the screen.
    unawaited(facade.settings.get(force: true));

    Navigator.of(hostContext).push(
      MaterialPageRoute(
        builder: (_) => DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: DeviceSettingsPage(
            device: device,
            schema: uiSchema,
          ),
        ),
      ),
    );
  }
}
