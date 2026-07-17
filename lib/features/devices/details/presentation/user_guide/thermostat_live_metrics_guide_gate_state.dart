part of 'thermostat_live_metrics_guide_gate.dart';

class _ThermostatLiveMetricsGuideGateState
    extends State<ThermostatLiveMetricsGuideGate> {
  static const _topic = UserGuideTopic.thermostatLiveMetricsV1;

  bool _automaticStartScheduled = false;

  void _scheduleAutomaticStart(UserGuideState state) {
    if (_automaticStartScheduled ||
        !state.isLoaded ||
        state.isGuideSessionActive ||
        !state.shouldShowAutomatically(_topic)) {
      return;
    }
    _automaticStartScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _automaticStartScheduled = false;
      if (mounted && !widget.cubit.isClosed) {
        widget.cubit.startAutomaticGuide(_topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return BlocBuilder<UserGuideCubit, UserGuideState>(
      bloc: widget.cubit,
      buildWhen: (previous, current) =>
          previous.isLoaded != current.isLoaded ||
          previous.sessionSource != current.sessionSource ||
          previous.sessionTopic != current.sessionTopic ||
          previous.sessionPageIndex != current.sessionPageIndex ||
          previous.sessionSuppressedTopics != current.sessionSuppressedTopics ||
          previous.isCompleted(_topic) != current.isCompleted(_topic),
      builder: (context, state) {
        _scheduleAutomaticStart(state);
        final isActiveTopic =
            state.isGuideSessionActive && state.sessionTopic == _topic;
        final steps = <ThermostatUserGuideStep>[
          ThermostatUserGuideStep.liveMetrics,
          if (widget.modeBarTargetKey != null &&
              widget.onOpenModeSettings != null)
            ThermostatUserGuideStep.modes,
          if (widget.temperatureTargetKey != null &&
              widget.onOpenTemperatureSettings != null)
            ThermostatUserGuideStep.temperature,
        ];
        final pageIndex =
            state.sessionPageIndex.clamp(0, steps.length - 1).toInt();
        if (isActiveTopic &&
            steps[pageIndex] != ThermostatUserGuideStep.liveMetrics &&
            widget.interactionController.isOpen) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.interactionController.isOpen) {
              unawaited(widget.interactionController.close());
            }
          });
        }
        return AnimatedSwitcher(
          duration: disableAnimations ? Duration.zero : AppPalette.motionBase,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isActiveTopic
              ? _buildVisibleGuide(
                  context,
                  isAutomaticSession: state.isAutomaticSessionActive,
                  steps: steps,
                  pageIndex: pageIndex,
                )
              : const SizedBox.shrink(
                  key: ValueKey('thermostat-live-metrics-guide-hidden'),
                ),
        );
      },
    );
  }

  Widget _buildVisibleGuide(
    BuildContext context, {
    required bool isAutomaticSession,
    required List<ThermostatUserGuideStep> steps,
    required int pageIndex,
  }) {
    final step = steps[pageIndex];
    final previous =
        pageIndex == 0 ? null : () => widget.cubit.selectPage(pageIndex - 1);
    final next = pageIndex >= steps.length - 1
        ? null
        : () => widget.cubit.selectPage(pageIndex + 1);
    final s = S.of(context);
    final sourceKey = isAutomaticSession ? 'automatic' : 'manual';

    switch (step) {
      case ThermostatUserGuideStep.liveMetrics:
        return UserGuideCoachOverlay(
          key: ValueKey('thermostat-live-metrics-guide-$sourceKey'),
          interactionController: widget.interactionController,
          onExit: widget.cubit.finishGuideSession,
          showStepNavigation: true,
          stepIndex: pageIndex,
          stepCount: steps.length,
          onPrevious: previous,
          onNext: next,
        );
      case ThermostatUserGuideStep.modes:
        return UserGuideTargetCoachOverlay(
          key: ValueKey('thermostat-modes-guide-$sourceKey'),
          targetKey: widget.modeBarTargetKey!,
          title: s.UserGuideModesTitle,
          message: s.UserGuideModesMessage,
          actionLabel: s.UserGuideModesAction,
          actionIcon: Icons.touch_app_rounded,
          stepIndex: pageIndex,
          stepCount: steps.length,
          onAction: widget.onOpenModeSettings!,
          onSkip: _exitGuide,
          onPrevious: previous,
          onNext: next,
          preferAboveTarget: true,
        );
      case ThermostatUserGuideStep.temperature:
        return UserGuideTargetCoachOverlay(
          key: ValueKey('thermostat-temperature-guide-$sourceKey'),
          targetKey: widget.temperatureTargetKey!,
          title: s.UserGuideTemperatureTitle,
          message: s.UserGuideTemperatureMessage,
          actionLabel: s.UserGuideTemperatureAction,
          actionIcon: Icons.thermostat_rounded,
          stepIndex: pageIndex,
          stepCount: steps.length,
          onAction: widget.onOpenTemperatureSettings!,
          onSkip: _exitGuide,
          onPrevious: previous,
          onNext: next,
          targetMarkerAlignment: const Alignment(-0.2, -0.35),
        );
    }
  }

  void _exitGuide() {
    unawaited(widget.cubit.finishGuideSession());
  }
}
