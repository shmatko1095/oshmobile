part of 'user_guide_coach_overlay.dart';

class _UserGuideCoachOverlayState extends State<UserGuideCoachOverlay> {
  bool _settling = false;

  void _handlePanStart(DragStartDetails details) {
    if (_settling) return;
    widget.interactionController.startDrag();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_settling) return;
    widget.interactionController.updateDrag(details.delta);
  }

  Future<void> _handlePanEnd(DragEndDetails details) async {
    if (_settling) return;
    setState(() => _settling = true);
    final opened = await widget.interactionController.endDrag(
      details.velocity.pixelsPerSecond,
    );
    if (!mounted) return;
    if (opened) {
      await _finishSuccessfulGuide();
      return;
    }
    setState(() => _settling = false);
  }

  Future<void> _handlePanCancel() async {
    if (_settling) return;
    setState(() => _settling = true);
    await widget.interactionController.cancelDrag();
    if (mounted) setState(() => _settling = false);
  }

  Future<void> _openFromSemantics() async {
    if (_settling) return;
    setState(() => _settling = true);
    final opened = await widget.interactionController.open();
    if (!mounted) return;
    if (opened) {
      await _finishSuccessfulGuide();
      return;
    }
    setState(() => _settling = false);
  }

  Future<void> _skip() async {
    if (_settling) return;
    setState(() => _settling = true);
    await widget.interactionController.close();
    await widget.onExit();
  }

  Future<void> _finishSuccessfulGuide() async {
    if (mounted) setState(() => _settling = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.interactionController,
      builder: (context, child) {
        final isLiveMetricsVisible = widget.interactionController.isOpen;
        return PopScope(
          canPop: isLiveMetricsVisible,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !isLiveMetricsVisible) unawaited(_skip());
          },
          child: ExcludeSemantics(
            excluding: isLiveMetricsVisible,
            child: IgnorePointer(
              ignoring: isLiveMetricsVisible,
              child: child,
            ),
          ),
        );
      },
      child: Semantics(
        key: const ValueKey('user-guide-live-metrics-semantics'),
        scopesRoute: true,
        namesRoute: true,
        container: true,
        button: true,
        label: s.UserGuideLiveMetricsMessage,
        onTap: _openFromSemantics,
        explicitChildNodes: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: widget.interactionController,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final progress =
                          widget.interactionController.progress.clamp(0.0, 1.0);
                      final remaining = 1 - progress;
                      final clearHeight = constraints.maxHeight * remaining;
                      final contentOpacity =
                          (1 - progress * 1.6).clamp(0.0, 1.0);
                      final overlayBaseAlpha = isDark ? 0.54 : 0.48;
                      final overlayColor =
                          (isDark ? AppPalette.canvas : AppPalette.white)
                              .withValues(
                        alpha: overlayBaseAlpha * remaining,
                      );

                      return Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: clearHeight,
                            child: ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 7 * remaining,
                                  sigmaY: 7 * remaining,
                                ),
                                child: ColoredBox(color: overlayColor),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: clearHeight,
                            child: ClipRect(
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: contentOpacity,
                                  child: Transform.translate(
                                    offset: Offset(0, -72 * progress),
                                    child: SafeArea(
                                      child: Align(
                                        alignment: const Alignment(0, 0.55),
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.fromLTRB(
                                            24,
                                            72,
                                            24,
                                            148,
                                          ),
                                          child:
                                              UserGuideLiveMetricsIllustration(
                                            title: s.ThermostatLiveMetricsTitle,
                                            message:
                                                s.UserGuideLiveMetricsMessage,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 0,
                            height: 24,
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: (1 - progress * 20).clamp(0.0, 1.0),
                                child: DecoratedBox(
                                  key: const ValueKey(
                                    'user-guide-live-metrics-sheet-edge',
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppPalette.historySurface
                                        : AppPalette.white,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(
                                        AppPalette.radiusLg,
                                      ),
                                    ),
                                  ),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      width: 36,
                                      height: 4,
                                      margin: const EdgeInsets.only(top: 7),
                                      decoration: BoxDecoration(
                                        color: (isDark
                                                ? AppPalette.textSecondary
                                                : AppPalette.lightTextSecondary)
                                            .withValues(alpha: 0.52),
                                        borderRadius: BorderRadius.circular(
                                          AppPalette.radiusPill,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                key: const ValueKey('user-guide-live-metrics-coach'),
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                onPanCancel: _handlePanCancel,
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              child: SafeArea(
                bottom: false,
                child: AnimatedBuilder(
                  animation: widget.interactionController,
                  builder: (context, child) => Opacity(
                    opacity: (1 - widget.interactionController.progress * 4)
                        .clamp(0.0, 1.0),
                    child: child,
                  ),
                  child: Semantics(
                    button: true,
                    label: s.UserGuideSkip,
                    child: TextButton(
                      key: const ValueKey('user-guide-skip'),
                      onPressed: _settling ? null : _skip,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        foregroundColor: isDark
                            ? AppPalette.textPrimary
                            : AppPalette.lightTextStrong,
                      ),
                      child: Text(s.UserGuideSkip),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showStepNavigation)
              Positioned(
                left: 20,
                right: 20,
                bottom: 28,
                child: SafeArea(
                  top: false,
                  child: AnimatedBuilder(
                    animation: widget.interactionController,
                    builder: (context, child) => Opacity(
                      opacity: (1 - widget.interactionController.progress * 4)
                          .clamp(0.0, 1.0),
                      child: child,
                    ),
                    child: _buildStepNavigation(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNavigation(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary;
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: widget.onPrevious == null
                ? const SizedBox.shrink()
                : TextButton(
                    key: const ValueKey('user-guide-previous'),
                    onPressed: _settling ? null : widget.onPrevious,
                    child: Text(s.Back),
                  ),
          ),
        ),
        Semantics(
          label: s.StepOf(widget.stepIndex + 1, widget.stepCount),
          child: Text(
            '${widget.stepIndex + 1} / ${widget.stepCount}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: widget.onNext == null
                ? const SizedBox.shrink()
                : TextButton(
                    key: const ValueKey('user-guide-next'),
                    onPressed: _settling ? null : widget.onNext,
                    child: Text(s.Next),
                  ),
          ),
        ),
      ],
    );
  }
}
