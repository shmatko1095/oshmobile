class TemperatureHistoryPreviewCacheRecord {
  const TemperatureHistoryPreviewCacheRecord({
    required this.values,
    required this.timestamps,
    required this.savedAt,
    required this.windowStart,
    required this.windowEnd,
  });

  final List<double> values;
  final List<DateTime> timestamps;
  final DateTime savedAt;
  final DateTime? windowStart;
  final DateTime? windowEnd;

  double? get lastValue => values.isEmpty ? null : values.last;
}

abstract interface class TemperatureHistoryPreviewCache {
  Future<TemperatureHistoryPreviewCacheRecord?> read({
    required String namespace,
    required String seriesKey,
    required DateTime nowUtc,
    required Duration maxAge,
  });

  Future<void> write({
    required String namespace,
    required String seriesKey,
    required TemperatureHistoryPreviewCacheRecord record,
  });

  Future<void> remove({
    required String namespace,
    required String seriesKey,
  });
}
