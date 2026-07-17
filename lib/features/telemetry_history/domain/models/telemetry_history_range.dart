enum TelemetryHistoryRange {
  day,
  week,
  month,
  year,
  custom,
}

extension TelemetryHistoryRangeX on TelemetryHistoryRange {
  Duration get duration {
    return switch (this) {
      TelemetryHistoryRange.day => const Duration(hours: 24),
      TelemetryHistoryRange.week => const Duration(days: 7),
      TelemetryHistoryRange.month => const Duration(days: 30),
      TelemetryHistoryRange.year => const Duration(days: 365),
      TelemetryHistoryRange.custom => throw UnsupportedError(
          'A custom telemetry history range has no fixed duration.',
        ),
    };
  }
}
