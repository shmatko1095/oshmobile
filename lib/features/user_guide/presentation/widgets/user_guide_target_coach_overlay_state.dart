part of 'user_guide_target_coach_overlay.dart';

class _UserGuideTargetCoachOverlayState
    extends State<UserGuideTargetCoachOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hintController;
  Rect? _targetRect;
  bool? _animationsDisabled;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scheduleTargetMeasurement();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled != disabled) {
      _animationsDisabled = disabled;
      if (disabled) {
        _hintController
          ..stop()
          ..value = 0.55;
      } else {
        unawaited(_playHintTwice());
      }
    }
    _scheduleTargetMeasurement();
  }

  @override
  void didUpdateWidget(covariant UserGuideTargetCoachOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetKey != widget.targetKey) {
      _targetRect = null;
      _scheduleTargetMeasurement();
    }
  }

  Future<void> _playHintTwice() async {
    try {
      await _hintController.forward(from: 0).orCancel;
      await _hintController.forward(from: 0).orCancel;
      if (mounted) _hintController.value = 0.55;
    } on TickerCanceled {
      // Expected when the page is replaced or reduced motion is enabled.
    }
  }

  void _scheduleTargetMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTarget());
  }

  void _measureTarget() {
    if (!mounted) return;
    final targetBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (targetBox == null ||
        overlayBox == null ||
        !targetBox.hasSize ||
        !overlayBox.hasSize) {
      return;
    }

    final targetOrigin = targetBox.localToGlobal(Offset.zero);
    final overlayOrigin = overlayBox.localToGlobal(Offset.zero);
    final nextRect = (targetOrigin - overlayOrigin) & targetBox.size;
    if (_targetRect == nextRect) return;
    setState(() => _targetRect = nextRect);
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleTargetMeasurement();
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dimColor = (isDark ? AppPalette.canvas : AppPalette.white)
        .withValues(alpha: isDark ? 0.56 : 0.5);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onSkip();
      },
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        container: true,
        label: '${widget.title}. ${widget.message}',
        explicitChildNodes: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final target = _targetRect;
            if (target == null || size.isEmpty) {
              return ColoredBox(color: dimColor);
            }

            final hole = Rect.fromLTRB(
              (target.left - 8).clamp(0.0, size.width),
              (target.top - 8).clamp(0.0, size.height),
              (target.right + 8).clamp(0.0, size.width),
              (target.bottom + 8).clamp(0.0, size.height),
            );
            final padding = MediaQuery.paddingOf(context);
            final panelRect = _resolvePanelRect(
              size: size,
              target: hole,
              padding: padding,
            );

            return Stack(
              children: [
                _buildBarrier(
                  Rect.fromLTRB(0, 0, size.width, hole.top),
                  dimColor,
                ),
                _buildBarrier(
                  Rect.fromLTRB(0, hole.bottom, size.width, size.height),
                  dimColor,
                ),
                _buildBarrier(
                  Rect.fromLTRB(0, hole.top, hole.left, hole.bottom),
                  dimColor,
                ),
                _buildBarrier(
                  Rect.fromLTRB(hole.right, hole.top, size.width, hole.bottom),
                  dimColor,
                ),
                Positioned.fromRect(
                  rect: hole,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey('user-guide-target-highlight'),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppPalette.radiusXl,
                        ),
                        border: Border.all(
                          color: AppPalette.accentPrimary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.accentPrimary.withValues(
                              alpha: 0.22,
                            ),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: hole,
                  child: IgnorePointer(
                    child: Align(
                      alignment: widget.targetMarkerAlignment,
                      child: AnimatedBuilder(
                        animation: _hintController,
                        builder: (context, child) {
                          final value = _animationsDisabled == true
                              ? 0.55
                              : Curves.easeInOutCubic.transform(
                                  _hintController.value,
                                );
                          return Transform.scale(
                            scale: 0.9 + value * 0.14,
                            child: Opacity(
                              opacity: 0.58 + value * 0.34,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppPalette.accentPrimary.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppPalette.accentPrimary.withValues(
                                alpha: 0.72,
                              ),
                            ),
                          ),
                          child: !widget.showTargetMarkerIcon
                              ? null
                              : Icon(
                                  widget.actionIcon,
                                  color: AppPalette.accentPrimary,
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fromRect(
                  rect: panelRect,
                  child: Align(
                    alignment: panelRect.bottom <= hole.top
                        ? Alignment.bottomCenter
                        : Alignment.topCenter,
                    child: SingleChildScrollView(
                      child: _buildGuideCard(context),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 16,
                  child: SafeArea(
                    bottom: false,
                    child: TextButton(
                      key: const ValueKey('user-guide-skip'),
                      onPressed: widget.onSkip,
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
              ],
            );
          },
        ),
      ),
    );
  }

  Rect _resolvePanelRect({
    required Size size,
    required Rect target,
    required EdgeInsets padding,
  }) {
    final top = padding.top + 64;
    final bottom = size.height - padding.bottom - 16;
    final aboveHeight = target.top - 16 - top;
    final belowHeight = bottom - target.bottom - 16;
    final useAbove = widget.preferAboveTarget
        ? aboveHeight >= 150 || aboveHeight >= belowHeight
        : belowHeight < 150 && aboveHeight > belowHeight;

    if (useAbove) {
      return Rect.fromLTRB(20, top, size.width - 20, target.top - 16);
    }
    return Rect.fromLTRB(
      20,
      target.bottom + 16,
      size.width - 20,
      bottom,
    );
  }

  Widget _buildBarrier(Rect rect, Color dimColor) {
    final safeRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width.clamp(0.0, double.infinity),
      rect.height.clamp(0.0, double.infinity),
    );
    return Positioned.fromRect(
      rect: safeRect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: ColoredBox(color: dimColor),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextStrong;
    final bodyColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary;
    final surface =
        isDark ? AppPalette.historySurface : AppPalette.lightSurfaceSoft;

    return Material(
      key: const ValueKey('user-guide-target-card'),
      color: surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(AppPalette.radiusLg),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: bodyColor,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              key: const ValueKey('user-guide-target-action'),
              onPressed: widget.onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 48),
                foregroundColor: AppPalette.accentPrimary,
              ),
              icon: Icon(widget.actionIcon, size: 20),
              label: Text(widget.actionLabel),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: widget.onPrevious == null
                        ? const SizedBox.shrink()
                        : TextButton(
                            key: const ValueKey('user-guide-previous'),
                            onPressed: widget.onPrevious,
                            child: Text(s.Back),
                          ),
                  ),
                ),
                Semantics(
                  label: s.StepOf(widget.stepIndex + 1, widget.stepCount),
                  child: Text(
                    '${widget.stepIndex + 1} / ${widget.stepCount}',
                    style: TextStyle(
                      color: bodyColor,
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
                            onPressed: widget.onNext,
                            child: Text(s.Next),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
