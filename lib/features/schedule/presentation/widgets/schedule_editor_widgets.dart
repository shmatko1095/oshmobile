import 'package:flutter/material.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/utils.dart';
import 'package:oshmobile/generated/l10n.dart';

bool _scheduleIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _schedulePrimaryTextColor(BuildContext context) =>
    _scheduleIsDark(context)
        ? AppPalette.textPrimary
        : AppPalette.lightTextPrimary;

Color _scheduleSecondaryTextColor(BuildContext context) =>
    _scheduleIsDark(context)
        ? AppPalette.textSecondary
        : AppPalette.lightTextSecondary;

Color _scheduleTileSurfaceColor(BuildContext context) =>
    _scheduleIsDark(context) ? AppPalette.surfaceRaised : AppPalette.white;

Color _scheduleTileBorderColor(BuildContext context) =>
    _scheduleIsDark(context) ? AppPalette.borderSoft : AppPalette.lightBorder;

class ScheduleAddPointFab extends StatelessWidget {
  const ScheduleAddPointFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bg =
        _scheduleIsDark(context) ? AppPalette.surfaceRaised : AppPalette.white;
    final shadow = _scheduleIsDark(context)
        ? AppPalette.black.withValues(alpha: 0.25)
        : AppPalette.lightTextPrimary.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: bg,
        foregroundColor: _schedulePrimaryTextColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        ),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }
}

class ScheduleEditorErrorRetry extends StatelessWidget {
  const ScheduleEditorErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(S.of(context).Retry),
          ),
        ],
      ),
    );
  }
}

class SchedulePointTile extends StatelessWidget {
  const SchedulePointTile({
    super.key,
    required this.timeText,
    required this.valueText,
    required this.daysMask,
    required this.showDays,
    required this.onTapTime,
    required this.onDecTemp,
    required this.onIncTemp,
    required this.onToggleDay,
    required this.onTapValue,
  });

  final String timeText;
  final String valueText;
  final int daysMask;
  final bool showDays;

  final VoidCallback onTapTime;
  final VoidCallback onDecTemp;
  final VoidCallback onIncTemp;
  final void Function(int dayBit) onToggleDay;
  final VoidCallback onTapValue;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      backgroundColor: _scheduleTileSurfaceColor(context),
      borderColor: _scheduleTileBorderColor(context),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (ctx, constraints) {
              final time = InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTapTime,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  child: Text(
                    timeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _schedulePrimaryTextColor(context),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );

              final stepper = FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: _TempRangeStepper(
                  valueText: valueText,
                  onDecTemp: onDecTemp,
                  onIncTemp: onIncTemp,
                  onTapValue: onTapValue,
                ),
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: time),
                  const SizedBox(width: 12),
                  Flexible(fit: FlexFit.loose, child: stepper),
                ],
              );
            },
          ),
          if (showDays) const SizedBox(height: 10),
          if (showDays)
            Row(
              children: [
                for (final d in WeekdayMask.order)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _DayChip(
                        label: shortLabel(context, d),
                        selected: WeekdayMask.has(daysMask, d),
                        onTap: () => onToggleDay(d),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TempRangeStepper extends StatelessWidget {
  const _TempRangeStepper({
    required this.valueText,
    required this.onDecTemp,
    required this.onIncTemp,
    required this.onTapValue,
  });

  final String valueText;
  final VoidCallback onDecTemp;
  final VoidCallback onIncTemp;
  final VoidCallback onTapValue;

  static const _coolBlue = AppPalette.accentPrimary;
  static const _warmRed = AppPalette.accentWarning;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Setpoint $valueText',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTapValue,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                valueText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _schedulePrimaryTextColor(context),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconBtn(
          icon: Icons.keyboard_arrow_down,
          onTap: onDecTemp,
          color: _coolBlue,
          semanticsLabel: 'Previous setpoint',
        ),
        const SizedBox(width: 4),
        _IconBtn(
          icon: Icons.keyboard_arrow_up,
          onTap: onIncTemp,
          color: _warmRed,
          semanticsLabel: 'Next setpoint',
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 28,
            color: color ?? _schedulePrimaryTextColor(context),
          ),
        ),
      ),
    );
  }
}

class ScheduleWeekdayFilterBar extends StatelessWidget {
  const ScheduleWeekdayFilterBar({
    super.key,
    required this.mask,
    required this.onToggle,
  });

  final int mask;
  final void Function(int dayBit) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final d in WeekdayMask.order)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DayChip(
                  label: shortLabel(context, d),
                  selected: WeekdayMask.has(mask, d),
                  onTap: () => onToggle(d),
                  dense: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppPalette.accentPrimary.withValues(alpha: 0.24)
        : AppPalette.transparent;
    final bd = selected
        ? AppPalette.accentPrimary.withValues(alpha: 0.42)
        : AppPalette.transparent;
    final fg = selected
        ? _schedulePrimaryTextColor(context)
        : _scheduleSecondaryTextColor(context);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bd),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: dense ? 12 : 13,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
