import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/generated/l10n.dart';

part 'user_guide_target_coach_overlay_state.dart';

class UserGuideTargetCoachOverlay extends StatefulWidget {
  const UserGuideTargetCoachOverlay({
    super.key,
    required this.targetKey,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.stepIndex,
    required this.stepCount,
    required this.onAction,
    required this.onSkip,
    this.onPrevious,
    this.onNext,
    this.preferAboveTarget = false,
    this.targetMarkerAlignment = Alignment.center,
    this.showTargetMarkerIcon = false,
  });

  final GlobalKey targetKey;
  final String title;
  final String message;
  final String actionLabel;
  final IconData actionIcon;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onAction;
  final VoidCallback onSkip;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool preferAboveTarget;
  final Alignment targetMarkerAlignment;
  final bool showTargetMarkerIcon;

  @override
  State<UserGuideTargetCoachOverlay> createState() =>
      _UserGuideTargetCoachOverlayState();
}
