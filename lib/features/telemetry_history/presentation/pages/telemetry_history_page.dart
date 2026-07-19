import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_slide_view_model.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';
import 'package:oshmobile/features/telemetry_history/presentation/utils/telemetry_history_date_formatters.dart';
import 'package:oshmobile/features/telemetry_history/presentation/utils/telemetry_history_timestamp_formatter.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_bar_chart.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_line_chart.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_chart.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/telemetry_history_period_header.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/show_telemetry_history_date_range_sheet.dart';
import 'package:oshmobile/generated/l10n.dart';

part 'telemetry_history_page_helpers.dart';
part 'telemetry_history_page_sections.dart';
part 'telemetry_history_page_metric_slide.dart';
part 'telemetry_history_temperature_carousel.dart';

class TelemetryHistoryPage extends StatefulWidget {
  const TelemetryHistoryPage({
    super.key,
    this.title = 'History',
    this.initialSeriesKey,
  });

  final String title;
  final String? initialSeriesKey;

  @override
  State<TelemetryHistoryPage> createState() => _TelemetryHistoryPageState();
}

class _TelemetryHistoryPageState extends State<TelemetryHistoryPage> {
  late final ScrollController _scrollController;
  late final PageController _temperaturePageController;
  final Map<String, GlobalKey> _metricKeys = <String, GlobalKey>{};
  final GlobalKey _temperatureCarouselKey = GlobalKey();
  Set<String> _enabledTemperatureSeries = <String>{};
  int _selectedTemperaturePage = 0;
  bool _initialAnchorScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final state = context.read<TelemetryHistoryCubit>().state;
    final temperatureIndices = _temperatureMetricIndices(state.metrics);
    final initialSeriesKey = widget.initialSeriesKey ?? state.metric.seriesKey;
    final initialPage = temperatureIndices.indexWhere(
      (index) => state.metrics[index].seriesKey == initialSeriesKey,
    );
    _selectedTemperaturePage = initialPage < 0 ? 0 : initialPage;
    _temperaturePageController = PageController(
      initialPage: _selectedTemperaturePage,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _temperaturePageController.dispose();
    super.dispose();
  }

  void _selectTemperaturePage(int page, List<int> metricIndices) {
    if (page < 0 || page >= metricIndices.length) return;
    if (_selectedTemperaturePage != page) {
      setState(() => _selectedTemperaturePage = page);
    }
    unawaited(
      context
          .read<TelemetryHistoryCubit>()
          .selectMetricIndex(metricIndices[page]),
    );
  }

  void _toggleTemperatureSeries(String id) {
    setState(() {
      final next = <String>{..._enabledTemperatureSeries};
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      _enabledTemperatureSeries = next;
    });
  }

  Future<void> _openDateRangePicker(
    TelemetryHistoryCubit cubit,
    TelemetryHistoryWindow window,
  ) async {
    final selectedRange = await showTelemetryHistoryDateRangeSheet(
      context: context,
      window: window,
      nowLocal: cubit.nowLocal,
      retentionPolicy: cubit.retentionPolicy,
    );
    if (!mounted || selectedRange == null) return;
    final applied = await cubit.selectCustomRange(
      startLocal: selectedRange.start,
      endInclusiveLocal: selectedRange.end,
    );
    if (!mounted || applied) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(S.of(context).TelemetryHistoryCalendarRangeTooLong)),
    );
  }

  void _syncMetricKeys(TelemetryHistoryState state) {
    for (final metric in state.metrics) {
      if (_isTemperatureMetric(metric)) continue;
      _metricKeys.putIfAbsent(metric.seriesKey, GlobalKey.new);
    }

    final initialSeriesKey = widget.initialSeriesKey;
    if (_initialAnchorScheduled || initialSeriesKey == null) {
      return;
    }
    final initialMetricIndex = state.metrics.indexWhere(
      (metric) => metric.seriesKey == initialSeriesKey,
    );
    if (initialMetricIndex < 0) {
      return;
    }
    final initialMetric = state.metrics[initialMetricIndex];
    final targetKey = _isTemperatureMetric(initialMetric)
        ? _temperatureCarouselKey
        : _metricKeys[initialSeriesKey];
    if (targetKey == null) return;

    _initialAnchorScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = targetKey.currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.02,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppPalette.motionSlow,
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return BlocBuilder<TelemetryHistoryCubit, TelemetryHistoryState>(
      builder: (context, state) {
        _syncMetricKeys(state);
        final cubit = context.read<TelemetryHistoryCubit>();
        final rangeOptions = <TelemetryHistoryRange, String>{
          for (final range in _visibleRanges) range: _rangeLabel(s, range),
        };
        final temperatureMetricIndices =
            _temperatureMetricIndices(state.metrics);
        final panelChildren = <Widget>[];

        void addPanelSection(Widget section) {
          if (panelChildren.isNotEmpty) {
            panelChildren.add(
              Divider(
                height: 1,
                indent: AppPalette.spaceLg,
                endIndent: AppPalette.spaceLg,
                color: _historyBorderColor(context),
              ),
            );
          }
          panelChildren.add(section);
        }

        var temperatureCarouselAdded = false;
        for (var index = 0; index < state.metrics.length; index++) {
          final metric = state.metrics[index];
          if (_isTemperatureMetric(metric)) {
            if (temperatureCarouselAdded) continue;
            temperatureCarouselAdded = true;
            addPanelSection(
              KeyedSubtree(
                key: _temperatureCarouselKey,
                child: _TemperatureMetricCarousel(
                  state: state,
                  metricIndices: temperatureMetricIndices,
                  controller: _temperaturePageController,
                  selectedPage: _selectedTemperaturePage,
                  localeTag: localeTag,
                  s: s,
                  enabledTemperatureSeries: _enabledTemperatureSeries,
                  onToggleTemperatureSeries: _toggleTemperatureSeries,
                  onPageChanged: (page) => _selectTemperaturePage(
                    page,
                    temperatureMetricIndices,
                  ),
                ),
              ),
            );
            continue;
          }

          addPanelSection(
            KeyedSubtree(
              key: _metricKeys[metric.seriesKey],
              child: _MetricSlide(
                state: state,
                metric: metric,
                metricIndex: index,
                localeTag: localeTag,
                s: s,
                enabledTemperatureSeries: _enabledTemperatureSeries,
                onToggleTemperatureSeries: _toggleTemperatureSeries,
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: cubit.refresh,
            child: CustomScrollView(
              key: const ValueKey('telemetry-history-dashboard-scroll'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PinnedHeaderSliver(
                  child: AnimatedSize(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.hardEdge,
                    child: TelemetryHistoryPeriodHeader(
                      options: rangeOptions,
                      selectedRange: state.range,
                      periodLabel: _periodLabel(
                        window: state.window,
                        localeTag: localeTag,
                      ),
                      canGoPrevious: cubit.canGoPrevious,
                      canGoNext: cubit.canGoNext,
                      isCustom: state.range == TelemetryHistoryRange.custom,
                      openCalendarTooltip:
                          s.TelemetryHistoryCalendarOpenTooltip,
                      clearCustomRangeTooltip:
                          s.TelemetryHistoryCalendarClearTooltip,
                      onRangeSelected: (range) {
                        if (range == state.range) return;
                        unawaited(cubit.selectRange(range));
                      },
                      onPrevious: () => unawaited(cubit.showPreviousPeriod()),
                      onNext: () => unawaited(cubit.showNextPeriod()),
                      onPeriodTap: () => unawaited(
                        _openDateRangePicker(cubit, state.window),
                      ),
                      onClearCustomRange: () =>
                          unawaited(cubit.clearCustomRange()),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppPalette.spaceLg,
                    AppPalette.spaceMd,
                    AppPalette.spaceLg,
                    AppPalette.spaceXl + MediaQuery.paddingOf(context).bottom,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _historySurfaceColor(context),
                        borderRadius:
                            BorderRadius.circular(AppPalette.radiusLg),
                        border: Border.all(
                          color: _historyBorderColor(context),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppPalette.radiusLg),
                        child: Column(children: panelChildren),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
