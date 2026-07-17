part of 'telemetry_history_page.dart';

const List<TelemetryHistoryRange> _visibleRanges = <TelemetryHistoryRange>[
  TelemetryHistoryRange.day,
  TelemetryHistoryRange.week,
  TelemetryHistoryRange.month,
  TelemetryHistoryRange.year,
];

bool _isTemperatureMetric(TelemetryHistoryMetric metric) {
  return metric.seriesKey.startsWith('climate_sensors.') &&
      metric.seriesKey.endsWith('.temp');
}

List<int> _temperatureMetricIndices(List<TelemetryHistoryMetric> metrics) {
  return <int>[
    for (var index = 0; index < metrics.length; index++)
      if (_isTemperatureMetric(metrics[index])) index,
  ];
}

bool _historyIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _historySurfaceColor(BuildContext context) =>
    _historyIsDark(context) ? AppPalette.historySurface : AppPalette.white;

Color _historyBorderColor(BuildContext context) => _historyIsDark(context)
    ? AppPalette.historyBorder.withValues(alpha: 0.58)
    : AppPalette.lightBorder;

Color _historyPrimaryTextColor(BuildContext context) => _historyIsDark(context)
    ? AppPalette.textPrimary
    : AppPalette.lightTextPrimary;

Color _historySecondaryTextColor(BuildContext context) =>
    _historyIsDark(context)
        ? AppPalette.historyTextSecondary
        : AppPalette.lightTextSecondary;

Color _historyMutedTextColor(BuildContext context) => _historyIsDark(context)
    ? AppPalette.historyTextSecondary.withValues(alpha: 0.78)
    : AppPalette.lightTextSubtle;

String _periodLabel({
  required TelemetryHistoryWindow window,
  required String localeTag,
}) {
  final start = window.startLocal;
  final inclusiveEnd = DateTime(
    window.endLocal.year,
    window.endLocal.month,
    window.endLocal.day - 1,
  );
  return switch (window.range) {
    TelemetryHistoryRange.day =>
      DateFormat('d MMMM y', localeTag).format(start),
    TelemetryHistoryRange.week => _weekPeriodLabel(
        start: start,
        end: inclusiveEnd,
        localeTag: localeTag,
      ),
    TelemetryHistoryRange.month =>
      _capitalizePeriodLabel(DateFormat('LLLL y', localeTag).format(start)),
    TelemetryHistoryRange.year => DateFormat('y', localeTag).format(start),
    TelemetryHistoryRange.custom => _customPeriodLabel(
        start: start,
        end: inclusiveEnd,
        localeTag: localeTag,
      ),
  };
}

String _customPeriodLabel({
  required DateTime start,
  required DateTime end,
  required String localeTag,
}) {
  return telemetryHistoryDateRangeLabel(
    startLocal: start,
    endInclusiveLocal: end,
    localeTag: localeTag,
  );
}

String _capitalizePeriodLabel(String value) {
  if (value.isEmpty) return value;
  return '${value.characters.first.toUpperCase()}${value.substring(value.characters.first.length)}';
}

String _weekPeriodLabel({
  required DateTime start,
  required DateTime end,
  required String localeTag,
}) {
  if (start.year == end.year && start.month == end.month) {
    return '${start.day}–${DateFormat('d MMMM y', localeTag).format(end)}';
  }
  if (start.year == end.year) {
    return '${DateFormat('d MMM', localeTag).format(start)} – '
        '${DateFormat('d MMM y', localeTag).format(end)}';
  }
  return '${DateFormat('d MMM y', localeTag).format(start)} – '
      '${DateFormat('d MMM y', localeTag).format(end)}';
}

String _fmtValue(double value, TelemetryHistoryMetric metric) {
  return TelemetryHistoryMetricValueFormatter.format(value, metric);
}

String _rangeLabel(S s, TelemetryHistoryRange range) {
  return switch (range) {
    TelemetryHistoryRange.day => s.TelemetryHistoryRangeDay,
    TelemetryHistoryRange.week => s.TelemetryHistoryRangeWeek,
    TelemetryHistoryRange.month => s.TelemetryHistoryRangeMonth,
    TelemetryHistoryRange.year => s.TelemetryHistoryRangeYear,
    TelemetryHistoryRange.custom => s.TelemetryHistoryRangeCustom,
  };
}

String _xAxisLabel({
  required DateTime timestamp,
  required TelemetryHistoryWindow window,
  required String localeTag,
}) {
  final local = timestamp.toLocal();
  return switch (window.range) {
    TelemetryHistoryRange.day => DateFormat.Hm(localeTag).format(local),
    TelemetryHistoryRange.week => DateFormat.Md(localeTag).format(local),
    TelemetryHistoryRange.month => DateFormat.Md(localeTag).format(local),
    TelemetryHistoryRange.year => DateFormat.MMM(localeTag).format(local),
    TelemetryHistoryRange.custom when window.durationDays <= 1 =>
      DateFormat.Hm(localeTag).format(local),
    TelemetryHistoryRange.custom when window.durationDays <= 45 =>
      DateFormat.MMMd(localeTag).format(local),
    TelemetryHistoryRange.custom =>
      DateFormat('MMM y', localeTag).format(local),
  };
}

String _tooltipLabel({
  required DateTime timestamp,
  required double value,
  required TelemetryHistoryMetric metric,
  required String localeTag,
}) {
  final local = timestamp.toLocal();
  final time = DateFormat.yMd(localeTag).add_Hm().format(local);
  return '$time\n${_fmtValue(value, metric)}';
}

String _tooltipMinValueLabel({
  required double value,
  required TelemetryHistoryMetric metric,
  required S s,
}) {
  return '${s.TelemetryHistoryStatMin}: ${_fmtValue(value, metric)}';
}

String _tooltipTimeLabel({
  required DateTime timestamp,
  required String localeTag,
}) {
  return DateFormat.yMd(localeTag).add_Hm().format(timestamp.toLocal());
}
