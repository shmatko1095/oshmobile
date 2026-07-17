part of 'thermostat_user_guide_target_host.dart';

class _ThermostatUserGuideTargetHostState
    extends State<ThermostatUserGuideTargetHost> {
  static const _topic = UserGuideTopic.thermostatLiveMetricsV1;

  final Object _hostToken = Object();
  final GlobalKey _temperatureTargetKey = GlobalKey(
    debugLabel: 'thermostat-user-guide-temperature-target',
  );
  final GlobalKey _modeBarTargetKey = GlobalKey(
    debugLabel: 'thermostat-user-guide-mode-bar-target',
  );

  @override
  void initState() {
    super.initState();
    _syncRegistration();
  }

  @override
  void didUpdateWidget(covariant ThermostatUserGuideTargetHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.registry != widget.registry ||
        oldWidget.enabled != widget.enabled) {
      if (oldWidget.enabled) {
        _unregisterHost(oldWidget.registry, oldWidget.cubit);
      }
      _syncRegistration();
    }
  }

  void _syncRegistration() {
    if (widget.enabled) {
      widget.registry.registerHost(_topic, _hostToken);
    }
  }

  void _unregisterHost(
    UserGuideHostRegistry registry,
    UserGuideCubit cubit,
  ) {
    registry.unregisterHost(_topic, _hostToken);
    if (cubit.isClosed) return;
    final state = cubit.state;
    if (!registry.hasHost(_topic) &&
        state.isGuideSessionActive &&
        state.sessionTopic == _topic) {
      cubit.cancelGuideSession(_topic);
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      _unregisterHost(widget.registry, widget.cubit);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _temperatureTargetKey,
      _modeBarTargetKey,
    );
  }
}
