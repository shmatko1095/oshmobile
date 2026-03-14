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
import 'package:oshmobile/generated/l10n.dart';

class TelemetryHistoryPage extends StatefulWidget {
  const TelemetryHistoryPage({
    super.key,
  });

  @override
  State<TelemetryHistoryPage> createState() => _TelemetryHistoryPageState();
}

class _TelemetryHistoryPageState extends State<TelemetryHistoryPage> {
  static const List<TelemetryHistoryRange> _visibleRanges =
      <TelemetryHistoryRange>[
    TelemetryHistoryRange.day,
    TelemetryHistoryRange.week,
    TelemetryHistoryRange.month,
    TelemetryHistoryRange.year,
  ];

  late final PageController _pageController;

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

  List<_ChartEntry> _chartEntries(
    TelemetryHistorySeries? series,
    TelemetryHistoryMetric metric,
  ) {
    if (series == null) return const <_ChartEntry>[];

    final entries = <_ChartEntry>[];
    for (final point in series.points) {
      final value = switch (metric.kind) {
        TelemetryHistoryMetricKind.numeric => point.avgValue ??
            point.lastNumericValue ??
            point.maxValue ??
            point.minValue,
        TelemetryHistoryMetricKind.boolean => point.trueRatio ??
            (point.lastBoolValue == null
                ? null
                : (point.lastBoolValue! ? 1.0 : 0.0)),
      };
      if (value == null) continue;
      entries.add(
        _ChartEntry(
          timestamp: point.bucketStart,
          value: value,
        ),
      );
    }
    return entries;
  }

  String _fmtValue(double value, TelemetryHistoryMetric metric) {
    if (metric.kind == TelemetryHistoryMetricKind.boolean) {
      return '${(value * 100).round()}%';
    }
    final unit = metric.unit.isEmpty ? '' : ' ${metric.unit}';
    return '${value.toStringAsFixed(1)}$unit';
  }

  String _rangeLabel(S s, TelemetryHistoryRange range) {
    return switch (range) {
      TelemetryHistoryRange.day => s.TelemetryHistoryRangeDay,
      TelemetryHistoryRange.week => s.TelemetryHistoryRangeWeek,
      TelemetryHistoryRange.month => s.TelemetryHistoryRangeMonth,
      TelemetryHistoryRange.year => s.TelemetryHistoryRangeYear,
    };
  }

  String _xAxisLabel({
    required DateTime timestamp,
    required TelemetryHistoryRange range,
    required String localeTag,
  }) {
    final local = timestamp.toLocal();
    return switch (range) {
      TelemetryHistoryRange.day =>
        DateFormat('MM/dd HH:mm', localeTag).format(local),
      TelemetryHistoryRange.week =>
        DateFormat('MM/dd', localeTag).format(local),
      TelemetryHistoryRange.month =>
        DateFormat('MM/dd', localeTag).format(local),
      TelemetryHistoryRange.year =>
        DateFormat('MM/yy', localeTag).format(local),
    };
  }

  String _tooltipLabel({
    required DateTime timestamp,
    required double value,
    required TelemetryHistoryMetric metric,
    required String localeTag,
  }) {
    final local = timestamp.toLocal();
    final time = DateFormat('MM/dd HH:mm', localeTag).format(local);
    return '$time\n${_fmtValue(value, metric)}';
  }

  List<_SummaryItem> _summaryItems(
    List<double> values,
    TelemetryHistoryMetric metric,
    S s,
  ) {
    final hasValues = values.isNotEmpty;
    final avg =
        hasValues ? values.reduce((a, b) => a + b) / values.length : null;
    final avgText = avg == null ? '--' : _fmtValue(avg, metric);

    if (metric.kind == TelemetryHistoryMetricKind.boolean) {
      return <_SummaryItem>[
        _SummaryItem(
          label: s.TelemetryHistoryStatAvg,
          value: avgText,
        ),
      ];
    }

    final minValue = hasValues ? values.reduce(math.min) : null;
    final maxValue = hasValues ? values.reduce(math.max) : null;

    return <_SummaryItem>[
      _SummaryItem(
        label: s.TelemetryHistoryStatMin,
        value: minValue == null ? '--' : _fmtValue(minValue, metric),
      ),
      _SummaryItem(
        label: s.TelemetryHistoryStatMax,
        value: maxValue == null ? '--' : _fmtValue(maxValue, metric),
      ),
      _SummaryItem(
        label: s.TelemetryHistoryStatAvg,
        value: avgText,
      ),
    ];
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

  Widget _buildMetricSlide(
    BuildContext context, {
    required TelemetryHistoryState state,
    required TelemetryHistoryMetric metric,
    required int metricIndex,
    required String localeTag,
    required S s,
  }) {
    final series = state.seriesFor(metric);
    final isLoading = state.isLoadingFor(metric);
    final errorMessage = state.errorFor(metric);
    final entries = _chartEntries(series, metric);
    final values = entries.map((entry) => entry.value).toList(growable: false);
    final timestamps =
        entries.map((entry) => entry.timestamp).toList(growable: false);
    final isEmpty = !isLoading && errorMessage == null && values.isEmpty;
    final summaryItems = _summaryItems(values, metric, s);
    final sensorName = (metric.subtitle ?? '').trim();
    final hasSensorIdentity = sensorName.isNotEmpty && metric.sensorId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          if (hasSensorIdentity) ...[
            _SensorIdentityBar(
              label: s.TelemetryHistorySensorLabel,
              sensorName: sensorName,
              isPrimary: metric.isPrimarySensor,
              mainLabel: s.SensorMainLabel,
              positionText: state.hasMultipleMetrics
                  ? s.TelemetryHistorySensorPosition(
                      metricIndex + 1,
                      state.metrics.length,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
          ],
          _SummaryPanel(items: summaryItems),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : (errorMessage != null)
                      ? _ErrorState(
                          title: s.TelemetryHistoryLoadFailed,
                          message: errorMessage,
                          retryLabel: s.Retry,
                          onRetry: () => context
                              .read<TelemetryHistoryCubit>()
                              .reloadMetric(metric),
                        )
                      : isEmpty
                          ? _EmptyState(
                              title: s.TelemetryHistoryNoData,
                            )
                          : HistoryLineChart(
                              values: values,
                              timestamps: timestamps,
                              windowStart: series?.from,
                              windowEnd: series?.to,
                              color: metric.kind ==
                                      TelemetryHistoryMetricKind.boolean
                                  ? AppPalette.accentWarning
                                  : AppPalette.accentPrimary,
                              strokeWidth: 2.0,
                              fill: true,
                              showGrid: false,
                              showAxes: true,
                              enableTouchTooltip: true,
                              valueLabelBuilder: (v) => _fmtValue(v, metric),
                              xAxisLabelBuilder: (ts) => _xAxisLabel(
                                timestamp: ts,
                                range: state.range,
                                localeTag: localeTag,
                              ),
                              tooltipBuilder: (ts, value) => _tooltipLabel(
                                timestamp: ts,
                                value: value,
                                metric: metric,
                                localeTag: localeTag,
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
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
          backgroundColor: AppPalette.canvas,
          appBar: AppBar(
            title: Text(state.metric.title),
          ),
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: state.metrics.length,
                  onPageChanged: (index) {
                    context
                        .read<TelemetryHistoryCubit>()
                        .selectMetricIndex(index);
                  },
                  itemBuilder: (context, index) => _buildMetricSlide(
                    context,
                    state: state,
                    metric: state.metrics[index],
                    metricIndex: index,
                    localeTag: localeTag,
                    s: s,
                  ),
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
              if (state.hasMultipleMetrics)
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  child: _PagerDots(
                    count: state.metrics.length,
                    active: state.selectedMetricIndex,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SensorIdentityBar extends StatelessWidget {
  const _SensorIdentityBar({
    required this.label,
    required this.sensorName,
    required this.isPrimary,
    required this.mainLabel,
    required this.positionText,
  });

  final String label;
  final String sensorName;
  final bool isPrimary;
  final String mainLabel;
  final String? positionText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        border: Border.all(color: AppPalette.borderSoft),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.accentPrimary.withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              size: 16,
              color: AppPalette.accentPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: AppPalette.motionFast,
                  child: Text(
                    sensorName,
                    key: ValueKey(sensorName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppPalette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPrimary) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.accentPrimary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
              ),
              child: Text(
                mainLabel,
                style: const TextStyle(
                  color: AppPalette.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (positionText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.surfaceAlt,
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
                border: Border.all(color: AppPalette.borderSoft),
              ),
              child: Text(
                positionText!,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.items,
  });

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _SummaryCell(item: items[i])),
            if (i < items.length - 1)
              Container(
                width: 1,
                height: 44,
                color: AppPalette.borderSoft.withValues(alpha: 0.9),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.item,
  });

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          style: const TextStyle(
            color: AppPalette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppPalette.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.options,
    required this.selectedRange,
    required this.onSelected,
  });

  final List<_RangeOption> options;
  final TelemetryHistoryRange selectedRange;
  final ValueChanged<TelemetryHistoryRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121317),
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        border: Border.all(color: AppPalette.borderSoft),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _RangeChip(
                label: option.label,
                selected: selectedRange == option.range,
                onTap: () => onSelected(option.range),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppPalette.motionBase,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF666A72) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppPalette.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppPalette.textPrimary : AppPalette.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PagerDots extends StatelessWidget {
  const _PagerDots({
    required this.count,
    required this.active,
  });

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppPalette.motionFast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: i == active ? 16 : 6,
            decoration: BoxDecoration(
              color: i == active
                  ? AppPalette.accentPrimary
                  : AppPalette.textMuted.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            ),
          ),
      ],
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _RangeOption {
  const _RangeOption({
    required this.range,
    required this.label,
  });

  final TelemetryHistoryRange range;
  final String label;
}

class _ChartEntry {
  const _ChartEntry({
    required this.timestamp,
    required this.value,
  });

  final DateTime timestamp;
  final double value;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppPalette.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onRetry(),
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stacked_line_chart_rounded,
            size: 92,
            color: AppPalette.textMuted.withValues(alpha: 0.46),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
