import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/telemetry_history_range_selector.dart';

class TelemetryHistoryPeriodHeader extends StatelessWidget {
  const TelemetryHistoryPeriodHeader({
    super.key,
    required this.options,
    required this.selectedRange,
    required this.periodLabel,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isCustom,
    required this.openCalendarTooltip,
    required this.clearCustomRangeTooltip,
    required this.onRangeSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onPeriodTap,
    required this.onClearCustomRange,
  });

  final Map<TelemetryHistoryRange, String> options;
  final TelemetryHistoryRange selectedRange;
  final String periodLabel;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isCustom;
  final String openCalendarTooltip;
  final String clearCustomRangeTooltip;
  final ValueChanged<TelemetryHistoryRange> onRangeSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPeriodTap;
  final VoidCallback onClearCustomRange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppPalette.textPrimary : AppPalette.lightTextPrimary;
    final mutedColor = isDark
        ? AppPalette.historyTextSecondary
        : AppPalette.lightTextSecondary;
    final material = MaterialLocalizations.of(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

    return ColoredBox(
      key: const ValueKey('telemetry-history-period-header'),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              children: [
                for (final child in previousChildren)
                  Positioned(top: 0, left: 0, right: 0, child: child),
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: isCustom
              ? Center(
                  key: const ValueKey('telemetry-history-custom-period'),
                  child: Row(
                    children: [
                      Expanded(
                        child: _periodButton(
                          textColor: textColor,
                          mutedColor: mutedColor,
                        ),
                      ),
                      const SizedBox(width: AppPalette.spaceSm),
                      IconButton(
                        key: const ValueKey(
                          'telemetry-history-custom-range-clear',
                        ),
                        onPressed: onClearCustomRange,
                        tooltip: clearCustomRangeTooltip,
                        constraints: const BoxConstraints.tightFor(
                          width: 44,
                          height: 44,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? AppPalette.historySurfaceAlt
                              : AppPalette.lightSurfaceSubtle,
                          side: BorderSide(
                            color: isDark
                                ? AppPalette.historyBorder.withValues(
                                    alpha: 0.7,
                                  )
                                : AppPalette.lightBorder,
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: mutedColor,
                      ),
                    ],
                  ),
                )
              : Column(
                  key: const ValueKey('telemetry-history-preset-period'),
                  children: [
                    TelemetryHistoryRangeSelector(
                      options: options,
                      selectedRange: selectedRange,
                      onSelected: onRangeSelected,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        IconButton(
                          key: const ValueKey(
                            'telemetry-history-period-previous',
                          ),
                          onPressed: canGoPrevious ? onPrevious : null,
                          tooltip: material.previousPageTooltip,
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: mutedColor,
                          disabledColor: mutedColor.withValues(alpha: 0.32),
                        ),
                        Expanded(
                          child: _periodButton(
                            textColor: textColor,
                            mutedColor: mutedColor,
                          ),
                        ),
                        IconButton(
                          key: const ValueKey(
                            'telemetry-history-period-next',
                          ),
                          onPressed: canGoNext ? onNext : null,
                          tooltip: material.nextPageTooltip,
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: mutedColor,
                          disabledColor: mutedColor.withValues(alpha: 0.32),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _periodButton({
    required Color textColor,
    required Color mutedColor,
  }) {
    return Semantics(
      button: true,
      label: periodLabel,
      hint: openCalendarTooltip,
      child: Tooltip(
        message: openCalendarTooltip,
        child: InkWell(
          key: const ValueKey('telemetry-history-period-open-calendar'),
          onTap: onPeriodTap,
          borderRadius: BorderRadius.circular(AppPalette.radiusMd),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: mutedColor,
                ),
                const SizedBox(width: AppPalette.spaceSm),
                Flexible(
                  child: Text(
                    periodLabel,
                    key: const ValueKey('telemetry-history-period-label'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
