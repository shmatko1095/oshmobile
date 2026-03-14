enum TemperatureHistoryPreviewStatus {
  loading,
  ready,
  error,
}

class TemperatureHistoryPreviewEntry {
  const TemperatureHistoryPreviewEntry({
    required this.status,
    required this.values,
    required this.lastValue,
    required this.updatedAt,
    this.errorMessage,
  });

  factory TemperatureHistoryPreviewEntry.loading({
    DateTime? updatedAt,
  }) {
    return TemperatureHistoryPreviewEntry(
      status: TemperatureHistoryPreviewStatus.loading,
      values: const <double>[],
      lastValue: null,
      updatedAt: updatedAt,
    );
  }

  final TemperatureHistoryPreviewStatus status;
  final List<double> values;
  final double? lastValue;
  final DateTime? updatedAt;
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
