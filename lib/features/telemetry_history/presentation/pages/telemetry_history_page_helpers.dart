part of 'telemetry_history_page.dart';

const List<TelemetryHistoryRange> _visibleRanges = <TelemetryHistoryRange>[
  TelemetryHistoryRange.day,
  TelemetryHistoryRange.week,
  TelemetryHistoryRange.month,
  TelemetryHistoryRange.year,
];
const String _toggleTemp = 'temp';
const String _toggleTarget = 'target';
const String _toggleHeating = 'heating';
const Color _tempInactiveColor = AppPalette.chartTempInactive;

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

bool _isTemperatureMetric(TelemetryHistoryMetric metric) {
  return metric.kind == TelemetryHistoryMetricKind.numeric &&
      metric.seriesKey.endsWith('.temp');
}

TelemetryHistoryMetric? _findComparisonMetric(
  TelemetryHistoryState state,
  String seriesKey,
) {
  for (final metric in state.comparisonMetrics) {
    if (metric.seriesKey == seriesKey) {
      return metric;
    }
  }
  return null;
}

Set<String> _selectedTemperatureToggleIds(
  List<_OverlayToggleOption> options,
  Set<String> enabledTemperatureSeries,
) {
  if (options.isEmpty) {
    return const <String>{};
  }
  final available = options.map((option) => option.id).toSet();
  return enabledTemperatureSeries.intersection(available);
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
        referenceSensorId: point.referenceSensorId,
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

List<_SummaryItem> _summaryItems(
  List<double> values,
  TelemetryHistoryMetric metric,
  S s,
) {
  final hasValues = values.isNotEmpty;
  final avg = hasValues ? values.reduce((a, b) => a + b) / values.length : null;
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

_NumericDomain _resolveNumericDomain(
  List<_ChartEntry> primaryEntries,
  List<_ChartEntry> targetEntries,
) {
  final values = <double>[
    ...primaryEntries.map((entry) => entry.value),
    ...targetEntries.map((entry) => entry.value),
  ];
  if (values.isEmpty) {
    return const _NumericDomain(min: 0, max: 1);
  }

  final minRaw = values.reduce(math.min);
  final maxRaw = values.reduce(math.max);
  final span = (maxRaw - minRaw).abs();
  if (span > 0.0001) {
    return _NumericDomain(min: minRaw, max: maxRaw);
  }

  final fallbackPadding = math.max(minRaw.abs() * 0.04, 1.0);
  return _NumericDomain(
    min: minRaw - fallbackPadding,
    max: maxRaw + fallbackPadding,
  );
}

List<_ChartEntry> _mapBooleanToTemperatureDomain(
  List<_ChartEntry> entries, {
  required _NumericDomain domain,
}) {
  if (entries.isEmpty) {
    return const <_ChartEntry>[];
  }
  final span = math.max((domain.max - domain.min).abs(), 2.0);
  final lower = domain.min + span * 0.08;
  final upper = domain.max - span * 0.08;
  final cappedUpper = upper <= lower ? lower + 1.0 : upper;

  return entries
      .map(
        (entry) => _ChartEntry(
          timestamp: entry.timestamp,
          value: lower + entry.value.clamp(0.0, 1.0) * (cappedUpper - lower),
          referenceSensorId: entry.referenceSensorId,
        ),
      )
      .toList(growable: false);
}

Color _temperaturePointColor(_ChartEntry entry, String sensorId) {
  final referenceId = entry.referenceSensorId?.trim();
  if (referenceId == null || referenceId.isEmpty) {
    return _tempInactiveColor;
  }
  return referenceId == sensorId
      ? AppPalette.accentPrimary
      : _tempInactiveColor;
}

Color _temperatureLineColor(
  List<_ChartEntry> entries,
  TelemetryHistoryMetric metric,
) {
  final sensorId = metric.sensorId?.trim();
  if (sensorId == null || sensorId.isEmpty || entries.isEmpty) {
    return AppPalette.accentPrimary;
  }

  for (final entry in entries) {
    final referenceId = entry.referenceSensorId?.trim();
    if (referenceId == null || referenceId.isEmpty) {
      continue;
    }
    return _temperaturePointColor(entry, sensorId);
  }
  return AppPalette.accentPrimary;
}

LinearGradient? _temperatureLineGradient(
  List<_ChartEntry> entries,
  TelemetryHistoryMetric metric, {
  DateTime? windowStart,
  DateTime? windowEnd,
}) {
  final sensorId = metric.sensorId?.trim();
  if (sensorId == null || sensorId.isEmpty || entries.length < 2) {
    return null;
  }
  final hasReferenceData = entries.any(
    (entry) => (entry.referenceSensorId?.trim().isNotEmpty ?? false),
  );
  if (!hasReferenceData) {
    return null;
  }

  final startUtc = windowStart?.toUtc();
  final endUtc = windowEnd?.toUtc();
  final hasWindow =
      startUtc != null && endUtc != null && endUtc.isAfter(startUtc);
  final spanMicros =
      hasWindow ? endUtc.difference(startUtc).inMicroseconds.toDouble() : 0.0;

  double stopForEntry(int index) {
    if (hasWindow && spanMicros > 0) {
      final offsetMicros = entries[index]
          .timestamp
          .toUtc()
          .difference(startUtc)
          .inMicroseconds
          .toDouble();
      return (offsetMicros / spanMicros).clamp(0.0, 1.0);
    }
    if (entries.length == 1) return 0.0;
    return (index / (entries.length - 1)).clamp(0.0, 1.0);
  }

  final colors = <Color>[];
  final stops = <double>[];
  var previousColor = _temperaturePointColor(entries.first, sensorId);

  colors.add(previousColor);
  stops.add(stopForEntry(0));
  var hasColorTransitions = false;

  for (var i = 1; i < entries.length; i++) {
    final currentColor = _temperaturePointColor(entries[i], sensorId);
    final currentStop = stopForEntry(i);
    if (currentColor != previousColor) {
      hasColorTransitions = true;
      colors.add(previousColor);
      stops.add(currentStop);
    }
    colors.add(currentColor);
    stops.add(currentStop);
    previousColor = currentColor;
  }

  if (stops.first > 0.0) {
    colors.insert(0, colors.first);
    stops.insert(0, 0.0);
  }
  if (stops.last < 1.0) {
    colors.add(colors.last);
    stops.add(1.0);
  }

  if (!hasColorTransitions) {
    return null;
  }

  return LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: colors,
    stops: stops,
  );
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

class _OverlayToggleOption {
  const _OverlayToggleOption({
    required this.id,
    required this.label,
    required this.metric,
    required this.color,
  });

  final String id;
  final String label;
  final TelemetryHistoryMetric metric;
  final Color color;
}

class _NumericDomain {
  const _NumericDomain({
    required this.min,
    required this.max,
  });

  final double min;
  final double max;
}

class _ChartEntry {
  const _ChartEntry({
    required this.timestamp,
    required this.value,
    this.referenceSensorId,
  });

  final DateTime timestamp;
  final double value;
  final String? referenceSensorId;
}
