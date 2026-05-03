import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/telemetry_history_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_line_chart.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_multi_line_chart.dart';
import 'package:oshmobile/generated/l10n.dart';

part 'telemetry_history_page_helpers.dart';
part 'telemetry_history_page_sections.dart';
part 'telemetry_history_page_metric_slide.dart';

class TelemetryHistoryPage extends StatefulWidget {
  const TelemetryHistoryPage({
    super.key,
  });

  @override
  State<TelemetryHistoryPage> createState() => _TelemetryHistoryPageState();
}

class _TelemetryHistoryPageState extends State<TelemetryHistoryPage> {
  late final PageController _pageController;
  Set<String> _enabledTemperatureSeries = <String>{};
  String? _comparisonLoadKey;

  @override
  void initState() {
    super.initState();
    final initialPage =
        context.read<TelemetryHistoryCubit>().state.selectedMetricIndex;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _ensureComparisonLoaded(
    BuildContext context,
    TelemetryHistoryState state,
    TelemetryHistoryMetric metric,
  ) {
    if (!_isTemperatureMetric(metric) || !state.hasComparisonMetrics) {
      return;
    }
    final loadKey = '${state.range.name}|${metric.seriesKey}';
    if (_comparisonLoadKey == loadKey) {
      return;
    }
    _comparisonLoadKey = loadKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<TelemetryHistoryCubit>()
          .ensureMetricsLoaded(state.comparisonMetrics);
    });
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

  void _syncPager(TelemetryHistoryState state) {
    if (!_pageController.hasClients) return;
    final page = _pageController.page?.round();
    if (page == state.selectedMetricIndex) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final current = _pageController.page?.round();
      if (current == state.selectedMetricIndex) return;
      _pageController.jumpToPage(state.selectedMetricIndex);
    });
  }

  void _selectMetric(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: AppPalette.motionBase,
        curve: Curves.easeOutCubic,
      );
      return;
    }

    context.read<TelemetryHistoryCubit>().selectMetricIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return BlocBuilder<TelemetryHistoryCubit, TelemetryHistoryState>(
      builder: (context, state) {
        _syncPager(state);
        final rangeOptions = _visibleRanges
            .map(
              (range) => _RangeOption(
                range: range,
                label: _rangeLabel(s, range),
              ),
            )
            .toList(growable: false);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(state.metric.title),
          ),
          body: Column(
            children: [
              if (state.hasMultipleMetrics)
                SafeArea(
                  bottom: false,
                  minimum: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _MetricSelector(
                    metrics: state.metrics,
                    selectedIndex: state.selectedMetricIndex,
                    labelBuilder: _metricSelectorLabel,
                    onSelected: _selectMetric,
                  ),
                ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: state.metrics.length,
                  onPageChanged: (index) {
                    context
                        .read<TelemetryHistoryCubit>()
                        .selectMetricIndex(index);
                  },
                  itemBuilder: (context, index) {
                    final metric = state.metrics[index];
                    _ensureComparisonLoaded(context, state, metric);
                    return _MetricSlide(
                      state: state,
                      metric: metric,
                      metricIndex: index,
                      localeTag: localeTag,
                      s: s,
                      enabledTemperatureSeries: _enabledTemperatureSeries,
                      onToggleTemperatureSeries: _toggleTemperatureSeries,
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                minimum: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  state.hasMultipleMetrics ? 4 : 10,
                ),
                child: _RangeSelector(
                  options: rangeOptions,
                  selectedRange: state.range,
                  onSelected: (range) {
                    if (range == state.range) return;
                    context.read<TelemetryHistoryCubit>().selectRange(range);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
