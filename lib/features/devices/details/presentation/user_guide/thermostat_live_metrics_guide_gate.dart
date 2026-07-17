import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/thermostat_live_metrics_interaction_controller.dart';
import 'package:oshmobile/features/devices/details/presentation/user_guide/thermostat_user_guide_step.dart';
import 'package:oshmobile/features/devices/details/presentation/user_guide/user_guide_coach_overlay.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_state.dart';
import 'package:oshmobile/features/user_guide/presentation/widgets/user_guide_target_coach_overlay.dart';
import 'package:oshmobile/generated/l10n.dart';

part 'thermostat_live_metrics_guide_gate_state.dart';

class ThermostatLiveMetricsGuideGate extends StatefulWidget {
  const ThermostatLiveMetricsGuideGate({
    super.key,
    required this.cubit,
    required this.interactionController,
    this.modeBarTargetKey,
    this.temperatureTargetKey,
    this.onOpenModeSettings,
    this.onOpenTemperatureSettings,
  });

  final UserGuideCubit cubit;
  final ThermostatLiveMetricsInteractionController interactionController;
  final GlobalKey? modeBarTargetKey;
  final GlobalKey? temperatureTargetKey;
  final VoidCallback? onOpenModeSettings;
  final VoidCallback? onOpenTemperatureSettings;

  @override
  State<ThermostatLiveMetricsGuideGate> createState() =>
      _ThermostatLiveMetricsGuideGateState();
}
