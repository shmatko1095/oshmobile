import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';

class TelemetryHistoryRetentionPolicy {
  const TelemetryHistoryRetentionPolicy({
    this.maxQueryDuration = const Duration(days: 370),
  });

  final Duration maxQueryDuration;

  DateTime earliestAvailableDay(DateTime nowLocal) {
    final local = nowLocal.toLocal().subtract(maxQueryDuration);
    return DateTime(local.year, local.month, local.day);
  }

  bool allowsCustomWindow(
    TelemetryHistoryWindow window, {
    required DateTime nowLocal,
  }) {
    if (window.range != TelemetryHistoryRange.custom) return false;

    final now = nowLocal.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final inclusiveEnd = DateTime(
      window.endLocal.year,
      window.endLocal.month,
      window.endLocal.day - 1,
    );
    final queryDuration = window.queryToUtc(now).difference(
          window.queryFromUtc,
        );

    return !window.startLocal.isBefore(earliestAvailableDay(now)) &&
        !window.startLocal.isAfter(today) &&
        !inclusiveEnd.isAfter(today) &&
        !queryDuration.isNegative &&
        queryDuration <= maxQueryDuration;
  }

  bool canGoPrevious(
    TelemetryHistoryWindow window, {
    required DateTime nowLocal,
  }) {
    if (window.range == TelemetryHistoryRange.custom) return false;
    final earliestAvailableUtc = nowLocal.toUtc().subtract(maxQueryDuration);
    return window.previous().endLocal.toUtc().isAfter(earliestAvailableUtc);
  }
}
