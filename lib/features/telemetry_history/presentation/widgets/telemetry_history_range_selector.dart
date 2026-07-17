import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';

class TelemetryHistoryRangeSelector extends StatelessWidget {
  const TelemetryHistoryRangeSelector({
    super.key,
    required this.options,
    required this.selectedRange,
    required this.onSelected,
  });

  final Map<TelemetryHistoryRange, String> options;
  final TelemetryHistoryRange selectedRange;
  final ValueChanged<TelemetryHistoryRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppPalette.historySurfaceAlt : AppPalette.lightSurfaceSubtle;
    final border = isDark
        ? AppPalette.historyBorder.withValues(alpha: 0.7)
        : AppPalette.lightBorder;

    return Container(
      key: const ValueKey('telemetry-history-range-selector'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppPalette.radiusMd),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: entry.key == selectedRange,
                label: entry.value,
                child: InkWell(
                  key: ValueKey('telemetry-history-range-${entry.key.name}'),
                  onTap: () => onSelected(entry.key),
                  borderRadius: BorderRadius.circular(13),
                  child: AnimatedContainer(
                    duration: AppPalette.motionBase,
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: entry.key == selectedRange
                          ? AppPalette.accentPrimary.withValues(
                              alpha: isDark ? 0.28 : 0.12,
                            )
                          : AppPalette.transparent,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: entry.key == selectedRange
                            ? (isDark
                                ? AppPalette.textPrimary
                                : AppPalette.lightTextPrimary)
                            : (isDark
                                ? AppPalette.historyTextSecondary
                                : AppPalette.lightTextSecondary),
                        fontSize: 13,
                        fontWeight: entry.key == selectedRange
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
