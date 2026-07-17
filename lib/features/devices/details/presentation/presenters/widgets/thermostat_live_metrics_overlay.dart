import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_live_metrics_interaction_controller.dart';

part 'thermostat_live_metrics_overlay_state.dart';

typedef ThermostatLiveMetricsContentBuilder = Widget Function(
  BuildContext context,
  ScrollController scrollController,
  VoidCallback close,
  FocusNode titleFocusNode,
);

typedef ThermostatLiveMetricsForegroundBuilder = Widget Function(
  BuildContext context,
  ThermostatLiveMetricsInteractionController interactionController,
);

class ThermostatLiveMetricsOverlay extends StatefulWidget {
  const ThermostatLiveMetricsOverlay({
    super.key,
    required this.dashboard,
    required this.contentBuilder,
    this.foregroundBuilder,
    this.enabled = true,
  });

  final Widget dashboard;
  final ThermostatLiveMetricsContentBuilder contentBuilder;
  final ThermostatLiveMetricsForegroundBuilder? foregroundBuilder;
  final bool enabled;

  @override
  State<ThermostatLiveMetricsOverlay> createState() =>
      _ThermostatLiveMetricsOverlayState();
}
