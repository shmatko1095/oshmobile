import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/coordination/user_guide_host_registry.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:oshmobile/features/user_guide/presentation/show_user_guide_modal.dart';

Future<void> openContextualUserGuide(
  BuildContext context, {
  UserGuideTopic topic = UserGuideTopic.thermostatLiveMetricsV1,
}) async {
  final cubit = context.read<UserGuideCubit>();
  final registry = context.read<UserGuideHostRegistry>();
  final navigator = Navigator.of(context, rootNavigator: true);

  navigator.popUntil((route) => route.isFirst);
  await WidgetsBinding.instance.endOfFrame;

  if (registry.hasHost(topic)) {
    cubit.startManualGuide(topic);
    return;
  }

  if (!navigator.mounted) return;
  await showUserGuideModal(
    navigator.context,
    cubit: cubit,
    topic: topic,
  );
}
