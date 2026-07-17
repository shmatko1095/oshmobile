import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';

class TelemetryHistoryWindow {
  const TelemetryHistoryWindow({
    required this.range,
    required this.startLocal,
    required this.endLocal,
  });

  factory TelemetryHistoryWindow.current({
    required TelemetryHistoryRange range,
    required DateTime nowLocal,
  }) {
    if (range == TelemetryHistoryRange.custom) {
      throw ArgumentError.value(
        range,
        'range',
        'Use TelemetryHistoryWindow.custom for a custom range.',
      );
    }
    return TelemetryHistoryWindow.containing(
      range: range,
      anchorLocal: nowLocal.toLocal(),
    );
  }

  factory TelemetryHistoryWindow.containing({
    required TelemetryHistoryRange range,
    required DateTime anchorLocal,
  }) {
    if (range == TelemetryHistoryRange.custom) {
      throw ArgumentError.value(
        range,
        'range',
        'Use TelemetryHistoryWindow.custom for a custom range.',
      );
    }
    final anchor = anchorLocal.toLocal();
    final dayStart = DateTime(anchor.year, anchor.month, anchor.day);
    final start = switch (range) {
      TelemetryHistoryRange.day => dayStart,
      TelemetryHistoryRange.week => DateTime(
          dayStart.year,
          dayStart.month,
          dayStart.day - (dayStart.weekday - DateTime.monday),
        ),
      TelemetryHistoryRange.month => DateTime(anchor.year, anchor.month),
      TelemetryHistoryRange.year => DateTime(anchor.year),
      TelemetryHistoryRange.custom => throw StateError(
          'Custom ranges are handled before preset window calculation.',
        ),
    };
    final end = switch (range) {
      TelemetryHistoryRange.day =>
        DateTime(start.year, start.month, start.day + 1),
      TelemetryHistoryRange.week =>
        DateTime(start.year, start.month, start.day + 7),
      TelemetryHistoryRange.month => DateTime(start.year, start.month + 1),
      TelemetryHistoryRange.year => DateTime(start.year + 1),
      TelemetryHistoryRange.custom => throw StateError(
          'Custom ranges are handled before preset window calculation.',
        ),
    };
    return TelemetryHistoryWindow(
      range: range,
      startLocal: start,
      endLocal: end,
    );
  }

  factory TelemetryHistoryWindow.custom({
    required DateTime startLocal,
    required DateTime endInclusiveLocal,
  }) {
    final first = DateTime(
      startLocal.toLocal().year,
      startLocal.toLocal().month,
      startLocal.toLocal().day,
    );
    final second = DateTime(
      endInclusiveLocal.toLocal().year,
      endInclusiveLocal.toLocal().month,
      endInclusiveLocal.toLocal().day,
    );
    final start = first.isAfter(second) ? second : first;
    final inclusiveEnd = first.isAfter(second) ? first : second;
    return TelemetryHistoryWindow(
      range: TelemetryHistoryRange.custom,
      startLocal: start,
      endLocal: DateTime(
        inclusiveEnd.year,
        inclusiveEnd.month,
        inclusiveEnd.day + 1,
      ),
    );
  }

  final TelemetryHistoryRange range;
  final DateTime startLocal;
  final DateTime endLocal;

  DateTime get queryFromUtc => startLocal.toUtc();

  DateTime queryToUtc(DateTime nowLocal) {
    final now = nowLocal.toLocal();
    return (endLocal.isAfter(now) ? now : endLocal).toUtc();
  }

  bool canGoNext(DateTime nowLocal) {
    if (range == TelemetryHistoryRange.custom) return false;
    final current = TelemetryHistoryWindow.current(
      range: range,
      nowLocal: nowLocal,
    );
    return startLocal.isBefore(current.startLocal);
  }

  TelemetryHistoryWindow previous() {
    final anchor = switch (range) {
      TelemetryHistoryRange.day =>
        DateTime(startLocal.year, startLocal.month, startLocal.day - 1),
      TelemetryHistoryRange.week =>
        DateTime(startLocal.year, startLocal.month, startLocal.day - 7),
      TelemetryHistoryRange.month =>
        DateTime(startLocal.year, startLocal.month - 1),
      TelemetryHistoryRange.year => DateTime(startLocal.year - 1),
      TelemetryHistoryRange.custom => startLocal,
    };
    if (range == TelemetryHistoryRange.custom) return this;
    return TelemetryHistoryWindow.containing(
      range: range,
      anchorLocal: anchor,
    );
  }

  TelemetryHistoryWindow next(DateTime nowLocal) {
    if (range == TelemetryHistoryRange.custom) return this;
    if (!canGoNext(nowLocal)) return this;
    final anchor = switch (range) {
      TelemetryHistoryRange.day =>
        DateTime(startLocal.year, startLocal.month, startLocal.day + 1),
      TelemetryHistoryRange.week =>
        DateTime(startLocal.year, startLocal.month, startLocal.day + 7),
      TelemetryHistoryRange.month =>
        DateTime(startLocal.year, startLocal.month + 1),
      TelemetryHistoryRange.year => DateTime(startLocal.year + 1),
      TelemetryHistoryRange.custom => startLocal,
    };
    return TelemetryHistoryWindow.containing(
      range: range,
      anchorLocal: anchor,
    );
  }

  double get durationDays {
    final calendarStart = DateTime.utc(
      startLocal.year,
      startLocal.month,
      startLocal.day,
    );
    final calendarEnd = DateTime.utc(
      endLocal.year,
      endLocal.month,
      endLocal.day,
    );
    return calendarEnd.difference(calendarStart).inDays.toDouble();
  }
}
