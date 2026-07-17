import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_live_metrics_interaction_controller.dart';
import 'package:oshmobile/features/user_guide/presentation/widgets/user_guide_live_metrics_illustration.dart';
import 'package:oshmobile/generated/l10n.dart';

part 'user_guide_coach_overlay_state.dart';

class UserGuideCoachOverlay extends StatefulWidget {
  const UserGuideCoachOverlay({
    super.key,
    required this.interactionController,
    required this.onExit,
    this.showStepNavigation = false,
    this.stepIndex = 0,
    this.stepCount = 1,
    this.onPrevious,
    this.onNext,
  });

  final ThermostatLiveMetricsInteractionController interactionController;
  final Future<void> Function() onExit;
  final bool showStepNavigation;
  final int stepIndex;
  final int stepCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  State<UserGuideCoachOverlay> createState() => _UserGuideCoachOverlayState();
}
