import 'dart:async';

import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';

part 'user_guide_live_metrics_illustration_state.dart';

class UserGuideLiveMetricsIllustration extends StatefulWidget {
  const UserGuideLiveMetricsIllustration({
    super.key,
    required this.title,
    required this.message,
    this.showSheetPreview = false,
  });

  final String title;
  final String message;
  final bool showSheetPreview;

  @override
  State<UserGuideLiveMetricsIllustration> createState() =>
      _UserGuideLiveMetricsIllustrationState();
}
