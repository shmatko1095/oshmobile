part of 'user_guide_live_metrics_illustration.dart';

class _UserGuideLiveMetricsIllustrationState
    extends State<UserGuideLiveMetricsIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _verticalOffset;
  late final Animation<double> _opacity;
  bool? _animationsDisabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _verticalOffset = Tween<double>(begin: 18, end: -20).animate(curve);
    _opacity = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.45, end: 1),
          weight: 30,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(1),
          weight: 45,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1, end: 0.25),
          weight: 25,
        ),
      ],
    ).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == disabled) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _controller
        ..stop()
        ..value = 0.45;
    } else {
      unawaited(_playHintTwice());
    }
  }

  Future<void> _playHintTwice() async {
    try {
      await _controller.forward(from: 0).orCancel;
      await _controller.forward(from: 0).orCancel;
      if (mounted) _controller.value = 0.45;
    } on TickerCanceled {
      // Expected when the page is disposed or reduced motion is enabled.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextStrong;
    final bodyColor =
        isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary;

    return Semantics(
      image: true,
      label: widget.message,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showSheetPreview) ...[
              _buildSheetPreview(context),
              const SizedBox(height: 24),
            ],
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset =
                    _animationsDisabled == true ? -2.0 : _verticalOffset.value;
                final opacity =
                    _animationsDisabled == true ? 1.0 : _opacity.value;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: const Icon(
                Icons.swipe_up_alt_rounded,
                size: 42,
                color: AppPalette.accentPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                widget.message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: bodyColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetPreview(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? AppPalette.canvas : AppPalette.lightSurfaceSoft;
    final sheet = isDark ? AppPalette.historySurface : AppPalette.white;
    final muted = isDark ? AppPalette.textMuted : AppPalette.lightTextSecondary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animationValue = _animationsDisabled == true
            ? 0.45
            : Curves.easeOutCubic.transform(_controller.value);
        final sheetFraction = 0.18 + animationValue * 0.52;
        return Container(
          key: const ValueKey('user-guide-live-metrics-preview'),
          width: 280,
          height: 150,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: canvas,
            borderRadius: BorderRadius.circular(AppPalette.radiusLg),
            border: Border.all(
              color: AppPalette.accentPrimary.withValues(alpha: 0.24),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                    left: 20,
                    right: 72,
                    top: 26,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: muted.withValues(alpha: 0.24),
                        borderRadius:
                            BorderRadius.circular(AppPalette.radiusPill),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 116,
                    top: 46,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: muted.withValues(alpha: 0.16),
                        borderRadius:
                            BorderRadius.circular(AppPalette.radiusPill),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: constraints.maxHeight * sheetFraction,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: sheet,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppPalette.radiusMd),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 34,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: muted.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(
                                    AppPalette.radiusPill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 26,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 150,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: AppPalette.accentPrimary.withValues(
                                    alpha: 0.38,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppPalette.radiusPill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
