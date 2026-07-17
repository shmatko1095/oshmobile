import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_retention_policy.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_window.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/telemetry_history_date_range_sheet.dart';

Future<DateTimeRange?> showTelemetryHistoryDateRangeSheet({
  required BuildContext context,
  required TelemetryHistoryWindow window,
  required DateTime nowLocal,
  TelemetryHistoryRetentionPolicy retentionPolicy =
      const TelemetryHistoryRetentionPolicy(),
}) {
  final localNow = nowLocal.toLocal();
  final today = DateUtils.dateOnly(localNow);
  final firstDate = retentionPolicy.earliestAvailableDay(localNow);
  final windowInclusiveEnd = DateTime(
    window.endLocal.year,
    window.endLocal.month,
    window.endLocal.day - 1,
  );
  final availableInclusiveEnd =
      windowInclusiveEnd.isAfter(today) ? today : windowInclusiveEnd;
  final initialWindow = TelemetryHistoryWindow.custom(
    startLocal: window.startLocal,
    endInclusiveLocal: availableInclusiveEnd,
  );
  final initialRangeIsAvailable =
      !initialWindow.startLocal.isBefore(firstDate) &&
          !initialWindow.startLocal.isAfter(today) &&
          !availableInclusiveEnd.isBefore(initialWindow.startLocal) &&
          retentionPolicy.allowsCustomWindow(
            initialWindow,
            nowLocal: localNow,
          );
  final initialRange = initialRangeIsAvailable
      ? DateTimeRange(
          start: initialWindow.startLocal,
          end: availableInclusiveEnd,
        )
      : null;
  final rawDisplayedMonth = initialRange?.end ?? window.startLocal;
  final displayedMonth = rawDisplayedMonth.isBefore(firstDate)
      ? firstDate
      : rawDisplayedMonth.isAfter(today)
          ? today
          : rawDisplayedMonth;
  final disableAnimations = MediaQuery.disableAnimationsOf(context);

  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppPalette.transparent,
    barrierColor: AppPalette.black54,
    isDismissible: true,
    enableDrag: true,
    sheetAnimationStyle: AnimationStyle(
      duration: disableAnimations ? Duration.zero : AppPalette.motionSlow,
      reverseDuration:
          disableAnimations ? Duration.zero : AppPalette.motionBase,
    ),
    builder: (sheetContext) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final orientation = MediaQuery.orientationOf(context);
          final heightFactor =
              orientation == Orientation.landscape ? 0.96 : 0.9;
          final sheetWidth = math.min(constraints.maxWidth, 720.0);
          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: sheetWidth,
              height: constraints.maxHeight * heightFactor,
              child: TelemetryHistoryDateRangeSheet(
                nowLocal: localNow,
                firstDateLocal: firstDate,
                displayedMonthLocal: displayedMonth,
                retentionPolicy: retentionPolicy,
                initialRange: initialRange,
              ),
            ),
          );
        },
      );
    },
  );
}
