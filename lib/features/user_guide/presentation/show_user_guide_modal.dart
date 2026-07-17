import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/user_guide/domain/models/user_guide_topic.dart';
import 'package:oshmobile/features/user_guide/presentation/cubit/user_guide_cubit.dart';
import 'package:oshmobile/features/user_guide/presentation/widgets/user_guide_modal.dart';

Future<void> showUserGuideModal(
  BuildContext context, {
  UserGuideCubit? cubit,
  UserGuideTopic topic = UserGuideTopic.thermostatLiveMetricsV1,
}) async {
  final effectiveCubit = cubit ?? context.read<UserGuideCubit>();
  final disableAnimations = MediaQuery.disableAnimationsOf(context);
  effectiveCubit.startManualGuide(topic);

  try {
    await Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: OshAnalyticsScreens.userGuide),
        opaque: false,
        barrierColor: AppPalette.transparent,
        transitionDuration:
            disableAnimations ? Duration.zero : AppPalette.motionSlow,
        reverseTransitionDuration:
            disableAnimations ? Duration.zero : AppPalette.motionBase,
        pageBuilder: (context, animation, secondaryAnimation) {
          return UserGuideModal(cubit: effectiveCubit);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (disableAnimations) return child;
          final eased = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(eased),
              child: child,
            ),
          );
        },
      ),
    );
  } finally {
    effectiveCubit.finishManualGuide();
  }
}
