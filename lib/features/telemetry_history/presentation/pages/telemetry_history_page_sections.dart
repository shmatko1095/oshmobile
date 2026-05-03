part of 'telemetry_history_page.dart';

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({
    required this.metrics,
    required this.selectedIndex,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<TelemetryHistoryMetric> metrics;
  final int selectedIndex;
  final String Function(TelemetryHistoryMetric metric) labelBuilder;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Center(
            child: _MetricChip(
              label: labelBuilder(metrics[index]),
              selected: selectedIndex == index,
              onTap: () => onSelected(index),
            ),
          );
        },
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppPalette.motionBase,
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppPalette.accentPrimary.withValues(
                  alpha: _historyIsDark(context) ? 0.28 : 0.12,
                )
              : _historySurfaceColor(context),
          borderRadius: BorderRadius.circular(AppPalette.radiusPill),
          border: Border.all(
            color: selected
                ? AppPalette.accentPrimary.withValues(alpha: 0.42)
                : _historyBorderColor(context),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected
                ? _historyPrimaryTextColor(context)
                : _historyMutedTextColor(context),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _SensorIdentityBar extends StatelessWidget {
  const _SensorIdentityBar({
    required this.sensorName,
    required this.isPrimary,
    required this.mainLabel,
    required this.positionText,
  });

  final String sensorName;
  final bool isPrimary;
  final String mainLabel;
  final String? positionText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _historySurfaceColor(context),
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        border: Border.all(color: _historyBorderColor(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppPalette.accentPrimary.withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              size: 16,
              color: AppPalette.accentPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: AppPalette.motionFast,
                  child: Text(
                    sensorName,
                    key: ValueKey(sensorName),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _historyPrimaryTextColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isPrimary) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppPalette.accentPrimary.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
              ),
              child: Text(
                mainLabel,
                style: TextStyle(
                  color: _historyPrimaryTextColor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (positionText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _historySurfaceAltColor(context),
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
                border: Border.all(color: _historyBorderColor(context)),
              ),
              child: Text(
                positionText!,
                style: TextStyle(
                  color: _historySecondaryTextColor(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.items,
  });

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _SummaryCell(item: items[i])),
            if (i < items.length - 1)
              Container(
                width: 1,
                height: 44,
                color: _historyBorderColor(context).withValues(alpha: 0.9),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.item,
  });

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          style: TextStyle(
            color: _historySecondaryTextColor(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _historyPrimaryTextColor(context),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _OverlaySeriesSelector extends StatelessWidget {
  const _OverlaySeriesSelector({
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<_OverlayToggleOption> options;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          _OverlaySeriesChip(
            option: options[i],
            selected: selectedIds.contains(options[i].id),
            onTap: () => onToggle(options[i].id),
          ),
          if (i < options.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _OverlaySeriesChip extends StatelessWidget {
  const _OverlaySeriesChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _OverlayToggleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppPalette.motionBase,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? option.color.withValues(alpha: 0.2)
                : AppPalette.transparent,
            borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            border: Border.all(
              color: selected
                  ? option.color.withValues(alpha: 0.72)
                  : AppPalette.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? option.color
                      : option.color.withValues(alpha: 0.42),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? _historyPrimaryTextColor(context)
                      : _historyMutedTextColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.options,
    required this.selectedRange,
    required this.onSelected,
  });

  final List<_RangeOption> options;
  final TelemetryHistoryRange selectedRange;
  final ValueChanged<TelemetryHistoryRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _historySurfaceColor(context),
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        border: Border.all(color: _historyBorderColor(context)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _RangeChip(
                label: option.label,
                selected: selectedRange == option.range,
                onTap: () => onSelected(option.range),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppPalette.motionBase,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? AppPalette.accentPrimary.withValues(
                    alpha: _historyIsDark(context) ? 0.36 : 0.14,
                  )
                : AppPalette.transparent,
            borderRadius: BorderRadius.circular(AppPalette.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? _historyPrimaryTextColor(context)
                  : _historyMutedTextColor(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _historyPrimaryTextColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _historyMutedTextColor(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onRetry(),
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stacked_line_chart_rounded,
            size: 92,
            color: _historyMutedTextColor(context).withValues(alpha: 0.46),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: _historyMutedTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
