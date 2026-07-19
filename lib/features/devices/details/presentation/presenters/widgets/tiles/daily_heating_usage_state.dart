enum DailyHeatingUsageStatus { initial, loading, ready, error }

class DailyHeatingUsageState {
  const DailyHeatingUsageState({
    required this.status,
    this.loadFactorPercent,
    this.coverageRatio = 0,
    this.updatedAt,
    this.windowStart,
    this.windowEnd,
    this.errorMessage,
  });

  const DailyHeatingUsageState.initial()
      : status = DailyHeatingUsageStatus.initial,
        loadFactorPercent = null,
        coverageRatio = 0,
        updatedAt = null,
        windowStart = null,
        windowEnd = null,
        errorMessage = null;

  final DailyHeatingUsageStatus status;
  final double? loadFactorPercent;
  final double coverageRatio;
  final DateTime? updatedAt;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final String? errorMessage;

  DailyHeatingUsageState copyWith({
    DailyHeatingUsageStatus? status,
    double? loadFactorPercent,
    double? coverageRatio,
    DateTime? updatedAt,
    DateTime? windowStart,
    DateTime? windowEnd,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return DailyHeatingUsageState(
      status: status ?? this.status,
      loadFactorPercent: loadFactorPercent ?? this.loadFactorPercent,
      coverageRatio: coverageRatio ?? this.coverageRatio,
      updatedAt: updatedAt ?? this.updatedAt,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}
