part of 'user_guide_modal.dart';

class _UserGuideModalState extends State<UserGuideModal> {
  late final PageController _pageController;

  bool get _disableAnimations => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.cubit.state.sessionPageIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _next(int currentPage, int pageCount) async {
    if (currentPage >= pageCount - 1) return;
    if (_disableAnimations) {
      _pageController.jumpToPage(currentPage + 1);
      return;
    }
    await _pageController.animateToPage(
      currentPage + 1,
      duration: AppPalette.motionSlow,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlayColor = (isDark ? AppPalette.canvas : AppPalette.white)
        .withValues(alpha: isDark ? 0.86 : 0.82);
    final titleColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextStrong;
    final pages = <Widget>[
      UserGuideLiveMetricsIllustration(
        title: s.ThermostatLiveMetricsTitle,
        message: s.UserGuideLiveMetricsMessage,
        showSheetPreview: true,
      ),
    ];

    return OshAnalyticsScreenView(
      screenName: OshAnalyticsScreens.userGuide,
      child: Material(
        color: AppPalette.transparent,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: ColoredBox(
              color: overlayColor,
              child: SafeArea(
                child: Semantics(
                  scopesRoute: true,
                  namesRoute: true,
                  label: s.UserGuideTitle,
                  explicitChildNodes: true,
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.UserGuideTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              IconButton(
                                key: const ValueKey('user-guide-close'),
                                onPressed: _close,
                                tooltip: s.UserGuideCloseTooltip,
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<UserGuideCubit, UserGuideState>(
                          bloc: widget.cubit,
                          buildWhen: (previous, current) =>
                              previous.sessionPageIndex !=
                              current.sessionPageIndex,
                          builder: (context, state) {
                            return Column(
                              children: [
                                Expanded(
                                  child: PageView.builder(
                                    key: const ValueKey('user-guide-pages'),
                                    controller: _pageController,
                                    itemCount: pages.length,
                                    onPageChanged: widget.cubit.selectPage,
                                    itemBuilder: (context, index) {
                                      return LayoutBuilder(
                                        builder: (context, constraints) {
                                          return SingleChildScrollView(
                                            padding: const EdgeInsets.fromLTRB(
                                              24,
                                              32,
                                              24,
                                              24,
                                            ),
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                minHeight:
                                                    constraints.maxHeight - 56,
                                              ),
                                              child:
                                                  Center(child: pages[index]),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                _buildFooter(
                                  context,
                                  currentPage: state.sessionPageIndex,
                                  pageCount: pages.length,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required int currentPage,
    required int pageCount,
  }) {
    final s = S.of(context);
    final isLast = currentPage >= pageCount - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: s.StepOf(currentPage + 1, pageCount),
              child: Row(
                children: List<Widget>.generate(
                  pageCount,
                  (index) => AnimatedContainer(
                    key: ValueKey('user-guide-page-dot-$index'),
                    duration: _disableAnimations
                        ? Duration.zero
                        : AppPalette.motionBase,
                    width: index == currentPage ? 28 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: index == currentPage
                          ? AppPalette.accentPrimary
                          : AppPalette.textMuted.withValues(alpha: 0.42),
                      borderRadius:
                          BorderRadius.circular(AppPalette.radiusPill),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!isLast) ...[
            const SizedBox(width: 16),
            TextButton(
              key: const ValueKey('user-guide-next'),
              onPressed: () => _next(currentPage, pageCount),
              style: TextButton.styleFrom(
                minimumSize: const Size(112, 48),
                foregroundColor: AppPalette.accentPrimary,
              ),
              child: Text(s.Next),
            ),
          ],
        ],
      ),
    );
  }
}
