import 'package:intl/intl.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';

String telemetryHistoryTooltipTimestampLabel({
  required DateTime timestamp,
  required TelemetryHistoryWindow window,
  required String localeTag,
  DateTime Function(DateTime timestamp) localize = _toDeviceLocalTime,
}) {
  final local = localize(timestamp);
  return switch (window.range) {
    TelemetryHistoryRange.day =>
      DateFormat.yMd(localeTag).add_Hm().format(local),
    TelemetryHistoryRange.week => DateFormat.yMd(localeTag).format(local),
    TelemetryHistoryRange.month => DateFormat.yMd(localeTag).format(local),
    TelemetryHistoryRange.year => DateFormat.yMMMM(localeTag).format(local),
    TelemetryHistoryRange.custom when window.durationDays <= 1 =>
      DateFormat.yMd(localeTag).add_Hm().format(local),
    TelemetryHistoryRange.custom when window.durationDays <= 31 =>
      DateFormat.yMd(localeTag).format(local),
    TelemetryHistoryRange.custom => DateFormat.yMMMM(localeTag).format(local),
  };
}

DateTime _toDeviceLocalTime(DateTime timestamp) => timestamp.toLocal();
