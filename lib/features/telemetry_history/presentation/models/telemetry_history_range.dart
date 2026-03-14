enum TelemetryHistoryRange {
  h24,
  d7,
  d30,
  d45,
  d180,
  y1,
}

extension TelemetryHistoryRangeX on TelemetryHistoryRange {
  Duration get duration {
    return switch (this) {
      TelemetryHistoryRange.h24 => const Duration(hours: 24),
      TelemetryHistoryRange.d7 => const Duration(days: 7),
      TelemetryHistoryRange.d30 => const Duration(days: 30),
      TelemetryHistoryRange.d45 => const Duration(days: 45),
      TelemetryHistoryRange.d180 => const Duration(days: 180),
      TelemetryHistoryRange.y1 => const Duration(days: 365),
    };
  }

  String get label {
    return switch (this) {
      TelemetryHistoryRange.h24 => '24h',
      TelemetryHistoryRange.d7 => '7d',
      TelemetryHistoryRange.d30 => '30d',
      TelemetryHistoryRange.d45 => '45d',
      TelemetryHistoryRange.d180 => '180d',
      TelemetryHistoryRange.y1 => '1y',
    };
  }
}
