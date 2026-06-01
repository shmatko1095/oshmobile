part of 'telemetry_history_page.dart';

const List<TelemetryHistoryRange> _visibleRanges = <TelemetryHistoryRange>[
  TelemetryHistoryRange.day,
  TelemetryHistoryRange.week,
  TelemetryHistoryRange.month,
  TelemetryHistoryRange.year,
];

bool _historyIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _historySurfaceColor(BuildContext context) =>
    _historyIsDark(context) ? AppPalette.surfaceRaised : AppPalette.white;

Color _historySurfaceAltColor(BuildContext context) => _historyIsDark(context)
    ? AppPalette.surfaceAlt
    : AppPalette.lightSurfaceSubtle;

Color _historyBorderColor(BuildContext context) =>
    _historyIsDark(context) ? AppPalette.borderSoft : AppPalette.lightBorder;

Color _historyPrimaryTextColor(BuildContext context) => _historyIsDark(context)
    ? AppPalette.textPrimary
    : AppPalette.lightTextPrimary;

Color _historySecondaryTextColor(BuildContext context) =>
    _historyIsDark(context)
        ? AppPalette.textSecondary
        : AppPalette.lightTextSecondary;

Color _historyMutedTextColor(BuildContext context) =>
    _historyIsDark(context) ? AppPalette.textMuted : AppPalette.lightTextSubtle;

String _fmtValue(double value, TelemetryHistoryMetric metric) {
  return TelemetryHistoryMetricValueFormatter.format(value, metric);
}

String _rangeLabel(S s, TelemetryHistoryRange range) {
  return switch (range) {
    TelemetryHistoryRange.day => s.TelemetryHistoryRangeDay,
    TelemetryHistoryRange.week => s.TelemetryHistoryRangeWeek,
    TelemetryHistoryRange.month => s.TelemetryHistoryRangeMonth,
    TelemetryHistoryRange.year => s.TelemetryHistoryRangeYear,
  };
}

String _metricSelectorLabel(TelemetryHistoryMetric metric) {
  final subtitle = (metric.subtitle ?? '').trim();
  if (subtitle.isNotEmpty) return subtitle;
  return metric.title;
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
    TelemetryHistoryRange.week => DateFormat('MM/dd', localeTag).format(local),
    TelemetryHistoryRange.month => DateFormat('MM/dd', localeTag).format(local),
    TelemetryHistoryRange.year => DateFormat('MM/yy', localeTag).format(local),
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

String _tooltipTimeLabel({
  required DateTime timestamp,
  required String localeTag,
}) {
  return DateFormat('MM/dd HH:mm', localeTag).format(timestamp.toLocal());
}

class _RangeOption {
  const _RangeOption({
    required this.range,
    required this.label,
  });

  final TelemetryHistoryRange range;
  final String label;
}
