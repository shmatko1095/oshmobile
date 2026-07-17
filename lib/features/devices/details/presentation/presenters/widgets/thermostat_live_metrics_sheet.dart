import 'package:flutter/material.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/domain/models/thermostat_dashboard_schema.dart';

class ThermostatLiveMetricsSheet extends StatelessWidget {
  const ThermostatLiveMetricsSheet({
    super.key,
    required this.title,
    required this.deviceTitle,
    required this.closeTooltip,
    required this.tiles,
    required this.scrollController,
    required this.onClose,
    required this.titleFocusNode,
    required this.tileBuilder,
    this.onOpenHistory,
    this.openHistoryLabel,
    this.openHistoryTooltip,
  }) : assert(
          onOpenHistory == null ||
              (openHistoryLabel != null && openHistoryTooltip != null),
        );

  final String title;
  final String deviceTitle;
  final String closeTooltip;
  final List<ThermostatTileSpec> tiles;
  final ScrollController scrollController;
  final VoidCallback onClose;
  final FocusNode titleFocusNode;
  final IndexedWidgetBuilder tileBuilder;
  final VoidCallback? onOpenHistory;
  final String? openHistoryLabel;
  final String? openHistoryTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale =
        (MediaQuery.textScalerOf(context).scale(12) / 12).clamp(1.0, 2.0);
    final useAccessibleSingleColumn = textScale > 1.3;

    return Material(
      key: const ValueKey('thermostat-live-metrics-sheet'),
      color: theme.scaffoldBackgroundColor,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomScrollView(
              key: const ValueKey('thermostat-live-metrics-scroll'),
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 5,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.28,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppPalette.radiusPill,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Focus(
                                  focusNode: titleFocusNode,
                                  child: Semantics(
                                    header: true,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          deviceTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.62),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                key: const ValueKey(
                                  'thermostat-live-metrics-close',
                                ),
                                onPressed: onClose,
                                tooltip: closeTooltip,
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: useAccessibleSingleColumn ? 420 : 280,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: useAccessibleSingleColumn ? 1.5 : 1.18,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      tileBuilder,
                      childCount: tiles.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.paddingOf(context).bottom +
                        (onOpenHistory == null ? 24 : 76),
                  ),
                ),
              ],
            ),
            if (onOpenHistory case final openHistory?)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.06,
                        ),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    minimum: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Tooltip(
                      message: openHistoryTooltip!,
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          key: const ValueKey(
                            'thermostat-live-metrics-show-history',
                          ),
                          onPressed: openHistory,
                          icon: const Icon(
                            Icons.show_chart_rounded,
                            size: 22,
                          ),
                          label: Text(
                            openHistoryLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: AppPalette.accentPrimary,
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
