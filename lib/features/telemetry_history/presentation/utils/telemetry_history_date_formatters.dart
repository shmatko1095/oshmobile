import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String telemetryHistoryDateRangeLabel({
  required DateTime startLocal,
  required DateTime endInclusiveLocal,
  required String localeTag,
}) {
  final start = DateUtils.dateOnly(startLocal.toLocal());
  final end = DateUtils.dateOnly(endInclusiveLocal.toLocal());
  if (DateUtils.isSameDay(start, end)) {
    return DateFormat('d MMMM y', localeTag).format(start);
  }
  if (start.year == end.year && start.month == end.month) {
    return '${start.day}–${DateFormat('d MMMM y', localeTag).format(end)}';
  }
  if (start.year == end.year) {
    return '${DateFormat('d MMM', localeTag).format(start)} – '
        '${DateFormat('d MMM y', localeTag).format(end)}';
  }
  return '${DateFormat('d MMM y', localeTag).format(start)} – '
      '${DateFormat('d MMM y', localeTag).format(end)}';
}

String telemetryHistorySingleDateLabel({
  required DateTime dateLocal,
  required String localeTag,
}) {
  return DateFormat('d MMMM y', localeTag).format(dateLocal.toLocal());
}
