class DailyEnergyUsageCacheRecord {
  const DailyEnergyUsageCacheRecord({
    required this.energyWh,
    required this.savedAt,
    required this.windowStart,
    required this.windowEnd,
  });

  final double energyWh;
  final DateTime savedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
}

abstract interface class DailyEnergyUsageCache {
  Future<DailyEnergyUsageCacheRecord?> read({
    required String namespace,
    required String seriesKey,
    required DateTime nowUtc,
    required Duration maxAge,
  });

  Future<void> write({
    required String namespace,
    required String seriesKey,
    required DailyEnergyUsageCacheRecord record,
  });

  Future<void> remove({
    required String namespace,
    required String seriesKey,
  });
}
