part of 'telemetry_history_page.dart';

class _TemperatureMetricCarousel extends StatelessWidget {
  const _TemperatureMetricCarousel({
    required this.state,
    required this.metricIndices,
    required this.controller,
    required this.selectedPage,
    required this.localeTag,
    required this.s,
    required this.enabledTemperatureSeries,
    required this.onToggleTemperatureSeries,
    required this.onPageChanged,
  });

  final TelemetryHistoryState state;
  final List<int> metricIndices;
  final PageController controller;
  final int selectedPage;
  final String localeTag;
  final S s;
  final Set<String> enabledTemperatureSeries;
  final ValueChanged<String> onToggleTemperatureSeries;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    assert(metricIndices.isNotEmpty);
    if (metricIndices.length == 1) {
      final metricIndex = metricIndices.single;
      return _MetricSlide(
        state: state,
        metric: state.metrics[metricIndex],
        metricIndex: metricIndex,
        localeTag: localeTag,
        s: s,
        enabledTemperatureSeries: enabledTemperatureSeries,
        onToggleTemperatureSeries: onToggleTemperatureSeries,
      );
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final extraHeight = ((textScale - 1).clamp(0, 1) * 72).toDouble();
    final hasOverlays = state.comparisonMetrics.isNotEmpty;
    final pageHeight = (hasOverlays ? 480.0 : 424.0) + extraHeight;
    final effectivePage = selectedPage.clamp(0, metricIndices.length - 1);
    final selectedMetric = state.metrics[metricIndices[effectivePage]];
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    void showPage(int page) {
      if (!controller.hasClients || page < 0 || page >= metricIndices.length) {
        return;
      }
      if (disableAnimations) {
        controller.jumpToPage(page);
        return;
      }
      controller.animateToPage(
        page,
        duration: AppPalette.motionBase,
        curve: Curves.easeOutCubic,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            key: const ValueKey('telemetry-history-temperature-carousel'),
            controller: controller,
            itemCount: metricIndices.length,
            allowImplicitScrolling: true,
            onPageChanged: onPageChanged,
            itemBuilder: (context, page) {
              final metricIndex = metricIndices[page];
              final metric = state.metrics[metricIndex];
              return Semantics(
                key: ValueKey(
                  'telemetry-history-temperature-${metric.seriesKey}',
                ),
                container: true,
                label:
                    '${metric.title}: ${metric.subtitle ?? metric.seriesKey}',
                value: '${page + 1} / ${metricIndices.length}',
                child: _MetricSlide(
                  state: state,
                  metric: metric,
                  metricIndex: metricIndex,
                  localeTag: localeTag,
                  s: s,
                  enabledTemperatureSeries: enabledTemperatureSeries,
                  onToggleTemperatureSeries: onToggleTemperatureSeries,
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const ValueKey(
                  'telemetry-history-temperature-previous',
                ),
                tooltip: MaterialLocalizations.of(context).previousPageTooltip,
                onPressed: effectivePage == 0
                    ? null
                    : () => showPage(effectivePage - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: AppPalette.spaceSm),
              Semantics(
                liveRegion: true,
                label: selectedMetric.subtitle ?? selectedMetric.title,
                value: '${effectivePage + 1} / ${metricIndices.length}',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var page = 0;
                          page < metricIndices.length;
                          page++) ...[
                        AnimatedContainer(
                          duration: disableAnimations
                              ? Duration.zero
                              : AppPalette.motionBase,
                          width: page == effectivePage ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: page == effectivePage
                                ? AppPalette.historyTemperature
                                : _historyMutedTextColor(context)
                                    .withValues(alpha: 0.42),
                            borderRadius:
                                BorderRadius.circular(AppPalette.radiusPill),
                          ),
                        ),
                        if (page < metricIndices.length - 1)
                          const SizedBox(width: 6),
                      ],
                      const SizedBox(width: AppPalette.spaceMd),
                      Text(
                        '${effectivePage + 1} / ${metricIndices.length}',
                        key: const ValueKey(
                          'telemetry-history-temperature-position',
                        ),
                        style: TextStyle(
                          color: _historySecondaryTextColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppPalette.spaceSm),
              IconButton(
                key: const ValueKey('telemetry-history-temperature-next'),
                tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                onPressed: effectivePage == metricIndices.length - 1
                    ? null
                    : () => showPage(effectivePage + 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
