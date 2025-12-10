import 'package:flutter/material.dart';

/// "Settings-like" slider row:
/// - title on top
/// - current value on the right
/// - slider below
/// - min/max labels at the bottom.
class SettingsSliderTile extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final double step;
  final String? unit;
  final ValueChanged<double> onChanged;

  const SettingsSliderTile({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final clampedMin = min < max ? min : max - 1;
    final clampedMax = max > min ? max : min + 1;
    final clampedValue = value.clamp(clampedMin, clampedMax);
    final divisionsDouble = (clampedMax - clampedMin) / (step <= 0 ? 1 : step);
    final divisions = divisionsDouble.isFinite ? divisionsDouble.round().clamp(1, 200) : 10;

    String _fmt(double v) {
      // Compact value formatting; add unit if present.
      final rounded = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
      return unit == null ? rounded : '$rounded $unit';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _fmt(clampedValue),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: Slider(
            value: clampedValue,
            min: clampedMin,
            max: clampedMax,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text(
                _fmt(clampedMin),
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                _fmt(clampedMax),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
