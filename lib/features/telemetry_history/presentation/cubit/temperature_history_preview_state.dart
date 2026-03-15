enum TemperatureHistoryPreviewStatus {
  loading,
  ready,
  error,
}

class TemperatureHistoryPreviewEntry {
  const TemperatureHistoryPreviewEntry({
    required this.status,
    required this.values,
    required this.timestamps,
    required this.lastValue,
    required this.updatedAt,
    required this.windowStart,
    required this.windowEnd,
    this.errorMessage,
  });

  factory TemperatureHistoryPreviewEntry.loading({
    DateTime? updatedAt,
  }) {
    return TemperatureHistoryPreviewEntry(
      status: TemperatureHistoryPreviewStatus.loading,
      values: const <double>[],
      timestamps: const <DateTime>[],
      lastValue: null,
      updatedAt: updatedAt,
      windowStart: null,
      windowEnd: null,
    );
  }

  final TemperatureHistoryPreviewStatus status;
  final List<double> values;
  final List<DateTime> timestamps;
  final double? lastValue;
  final DateTime? updatedAt;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final String? errorMessage;
}

class TemperatureHistoryPreviewState {
  const TemperatureHistoryPreviewState({
    required this.entriesBySeriesKey,
  });

  const TemperatureHistoryPreviewState.initial()
      : entriesBySeriesKey = const <String, TemperatureHistoryPreviewEntry>{};

  final Map<String, TemperatureHistoryPreviewEntry> entriesBySeriesKey;

  TemperatureHistoryPreviewEntry? entryOf(String seriesKey) {
    return entriesBySeriesKey[seriesKey];
  }

  TemperatureHistoryPreviewState upsert(
    String seriesKey,
    TemperatureHistoryPreviewEntry entry,
  ) {
    return TemperatureHistoryPreviewState(
      entriesBySeriesKey: <String, TemperatureHistoryPreviewEntry>{
        ...entriesBySeriesKey,
        seriesKey: entry,
      },
    );
  }
}
