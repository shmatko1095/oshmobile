enum DailyEnergyUsageStatus {
  initial,
  loading,
  ready,
  error,
}

class DailyEnergyUsageState {
  const DailyEnergyUsageState({
    required this.status,
    this.energyWh,
    this.updatedAt,
    this.windowStart,
    this.windowEnd,
    this.errorMessage,
    this.isFromPersistentCache = false,
  });

  const DailyEnergyUsageState.initial()
      : status = DailyEnergyUsageStatus.initial,
        energyWh = null,
        updatedAt = null,
        windowStart = null,
        windowEnd = null,
        errorMessage = null,
        isFromPersistentCache = false;

  final DailyEnergyUsageStatus status;
  final double? energyWh;
  final DateTime? updatedAt;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final String? errorMessage;
  final bool isFromPersistentCache;

  DailyEnergyUsageState copyWith({
    DailyEnergyUsageStatus? status,
    double? energyWh,
    bool clearEnergyWh = false,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
    DateTime? windowStart,
    bool clearWindowStart = false,
    DateTime? windowEnd,
    bool clearWindowEnd = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isFromPersistentCache,
  }) {
    return DailyEnergyUsageState(
      status: status ?? this.status,
      energyWh: clearEnergyWh ? null : energyWh ?? this.energyWh,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
      windowStart: clearWindowStart ? null : windowStart ?? this.windowStart,
      windowEnd: clearWindowEnd ? null : windowEnd ?? this.windowEnd,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isFromPersistentCache:
          isFromPersistentCache ?? this.isFromPersistentCache,
    );
  }
}
