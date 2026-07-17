part of 'thermostat_live_metrics_overlay.dart';

class _ThermostatLiveMetricsOverlayState
    extends State<ThermostatLiveMetricsOverlay> {
  static const Duration _motionDuration = Duration(milliseconds: 240);

  late final ThermostatLiveMetricsInteractionController _interactionController;
  final FocusNode _dashboardFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();

  double _sheetExtent = 0;
  bool _dashboardDragActive = false;
  bool _screenViewLogged = false;

  bool get _isOpen => _sheetExtent > 0.001;

  bool get _disableAnimations =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    _interactionController = ThermostatLiveMetricsInteractionController()
      ..addListener(_handleSheetChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureInteractionController();
  }

  @override
  void didUpdateWidget(covariant ThermostatLiveMetricsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configureInteractionController();
    if (!widget.enabled && oldWidget.enabled && _isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeSheet());
    }
  }

  @override
  void dispose() {
    _interactionController
      ..removeListener(_handleSheetChanged)
      ..dispose();
    _dashboardFocusNode.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _handleSheetChanged() {
    final nextExtent = _interactionController.progress;
    final wasOpen = _isOpen;
    final isOpen = nextExtent > 0.001;
    final reachedFullSize = nextExtent >= 0.999;
    final reachedClosedSize = nextExtent <= 0.001;

    _sheetExtent = nextExtent;
    if (wasOpen != isOpen || reachedFullSize || reachedClosedSize) {
      setState(() {});
    }

    if (reachedFullSize && !_screenViewLogged) {
      _screenViewLogged = true;
      unawaited(
        OshAnalytics.logScreenView(
          screenName: OshAnalyticsScreens.thermostatLiveMetrics,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _titleFocusNode.requestFocus();
      });
    } else if (reachedClosedSize) {
      _screenViewLogged = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enabled) _dashboardFocusNode.requestFocus();
      });
    }
  }

  void _configureInteractionController() {
    _interactionController.configure(
      enabled: widget.enabled,
      disableAnimations: _disableAnimations,
    );
  }

  bool _handleDashboardScrollNotification(ScrollNotification notification) {
    if (!widget.enabled || !_interactionController.sheetController.isAttached) {
      return false;
    }
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollStartNotification) {
      _dashboardDragActive = false;
      _interactionController.startDrag();
      return false;
    }

    if (notification is OverscrollNotification &&
        notification.overscroll > 0 &&
        _sheetExtent < 1) {
      _dashboardDragActive = true;
      _interactionController.updateDrag(Offset(0, -notification.overscroll));
      return false;
    }

    if (notification is ScrollEndNotification) {
      if (_dashboardDragActive) {
        final velocity = notification.dragDetails?.primaryVelocity ?? 0;
        _dashboardDragActive = false;
        unawaited(_interactionController.endDrag(Offset(0, velocity)));
      } else if (_interactionController.isDragging) {
        unawaited(_interactionController.cancelDrag());
      }
    }
    return false;
  }

  Future<void> _closeSheet() async {
    await _interactionController.close();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _dashboardFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isOpen) _closeSheet();
      },
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleDashboardScrollNotification,
            child: Focus(
              focusNode: _dashboardFocusNode,
              child: ExcludeSemantics(
                excluding: _isOpen,
                child: IgnorePointer(
                  ignoring: _isOpen && !_dashboardDragActive,
                  child: widget.dashboard,
                ),
              ),
            ),
          ),
          if (_isOpen)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _interactionController,
                builder: (context, child) {
                  final extent = _interactionController.progress;
                  return GestureDetector(
                    key: const ValueKey('thermostat-live-metrics-scrim'),
                    behavior: HitTestBehavior.opaque,
                    onTap: extent < 0.999 ? _closeSheet : null,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.46 * extent),
                    ),
                  );
                },
              ),
            ),
          if (widget.enabled)
            DraggableScrollableSheet(
              key: const ValueKey('thermostat-live-metrics-draggable-sheet'),
              controller: _interactionController.sheetController,
              initialChildSize: 0,
              minChildSize: 0,
              maxChildSize: 1,
              expand: true,
              snap: true,
              snapSizes: const <double>[0, 1],
              snapAnimationDuration: _disableAnimations
                  ? const Duration(milliseconds: 1)
                  : _motionDuration,
              builder: (context, scrollController) {
                return AnimatedBuilder(
                  animation: _interactionController,
                  builder: (context, child) {
                    final extent = _interactionController.progress;
                    final radius = AppPalette.radiusXl * (1 - extent);
                    return ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(radius),
                      ),
                      child: child,
                    );
                  },
                  child: widget.contentBuilder(
                    context,
                    scrollController,
                    _closeSheet,
                    _titleFocusNode,
                  ),
                );
              },
            ),
          if (widget.foregroundBuilder case final foregroundBuilder?)
            Positioned.fill(
              child: foregroundBuilder(context, _interactionController),
            ),
        ],
      ),
    );
  }
}
