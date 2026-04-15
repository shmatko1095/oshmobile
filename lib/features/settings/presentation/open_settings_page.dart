import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/settings/presentation/pages/device_settings_page.dart';

class DeviceSettingsNavigator {
  static void openInternal(
    BuildContext context, {
    required Device device,
    required DeviceFacade facade,
    required DeviceSnapshotCubit snapshotCubit,
  }) {
    final uiSchema = facade.settingsUiSchema;
    if (uiSchema == null || uiSchema.fieldsByPath.isEmpty) {
      return;
    }

    // Ensure settings are actively fetched when opening the screen.
    unawaited(facade.settings.get(force: true));
    final deviceLayout = snapshotCubit.state.details.data?.layout;
    unawaited(
      OshAnalytics.logEvent(
        OshAnalyticsEvents.deviceSettingsOpened,
        parameters: {'device_layout': deviceLayout},
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: OshAnalyticsScreens.deviceSettings),
        builder: (_) => DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: DeviceSettingsPage(
            schema: uiSchema,
          ),
        ),
      ),
    );
  }
}
