import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/entities/device/device.dart';
import 'package:oshmobile/features/device_about/presentation/pages/device_about_page.dart';

class DeviceAboutNavigator {
  const DeviceAboutNavigator._();

  static void openFromSession(
    BuildContext context, {
    required Device device,
    required DeviceFacade facade,
    required DeviceSnapshotCubit snapshotCubit,
  }) {
    final deviceLayout = snapshotCubit.state.details.data?.layout;
    unawaited(
      OshAnalytics.logEvent(
        OshAnalyticsEvents.deviceAboutOpened,
        parameters: {'device_layout': deviceLayout},
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: OshAnalyticsScreens.deviceAbout),
        builder: (_) => DeviceRouteScope.provide(
          facade: facade,
          snapshotCubit: snapshotCubit,
          child: DeviceAboutPage(deviceSn: device.sn),
        ),
      ),
    );
  }
}
