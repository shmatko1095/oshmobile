import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_retention_policy.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';
import 'package:oshmobile/features/telemetry_history/presentation/utils/telemetry_history_date_formatters.dart';
import 'package:oshmobile/generated/l10n.dart';

part 'telemetry_history_date_range_sheet_state.dart';

class TelemetryHistoryDateRangeSheet extends StatefulWidget {
  const TelemetryHistoryDateRangeSheet({
    super.key,
    required this.nowLocal,
    required this.firstDateLocal,
    required this.displayedMonthLocal,
    required this.retentionPolicy,
    this.initialRange,
  });

  final DateTime nowLocal;
  final DateTime firstDateLocal;
  final DateTime displayedMonthLocal;
  final TelemetryHistoryRetentionPolicy retentionPolicy;
  final DateTimeRange? initialRange;

  @override
  State<TelemetryHistoryDateRangeSheet> createState() =>
      TelemetryHistoryDateRangeSheetState();
}
