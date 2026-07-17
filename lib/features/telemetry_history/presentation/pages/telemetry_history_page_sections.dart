part of 'telemetry_history_page.dart';

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.items,
  });

  final List<TelemetryHistorySummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _SummaryCell(item: items[i])),
            if (i < items.length - 1) const SizedBox(width: 6),
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

  final TelemetryHistorySummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: item.label,
      value: item.value,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _historySecondaryTextColor(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _historyPrimaryTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlaySeriesSelector extends StatelessWidget {
  const _OverlaySeriesSelector({
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<TelemetryHistoryOverlayOption> options;
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

  final TelemetryHistoryOverlayOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        button: true,
        selected: selected,
        label: option.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppPalette.motionBase,
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              color: selected
                  ? option.color.withValues(alpha: 0.2)
                  : AppPalette.transparent,
              borderRadius: BorderRadius.circular(AppPalette.radiusPill),
              border: Border.all(
                color: selected
                    ? option.color.withValues(alpha: 0.28)
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
