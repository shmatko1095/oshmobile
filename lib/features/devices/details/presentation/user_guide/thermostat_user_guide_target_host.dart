import 'package:flutter/material.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/coordination/user_guide_host_registry.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';

part 'thermostat_user_guide_target_host_state.dart';

typedef ThermostatUserGuideTargetBuilder = Widget Function(
  BuildContext context,
  GlobalKey temperatureTargetKey,
  GlobalKey modeBarTargetKey,
);

class ThermostatUserGuideTargetHost extends StatefulWidget {
  const ThermostatUserGuideTargetHost({
    super.key,
    required this.builder,
    required this.registry,
    required this.cubit,
    required this.enabled,
  });

  final ThermostatUserGuideTargetBuilder builder;
  final UserGuideHostRegistry registry;
  final UserGuideCubit cubit;
  final bool enabled;

  @override
  State<ThermostatUserGuideTargetHost> createState() =>
      _ThermostatUserGuideTargetHostState();
}
