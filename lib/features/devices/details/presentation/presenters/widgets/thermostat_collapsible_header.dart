import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/device_presenter_chrome.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/utils/temperature_sensors_resolver.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_minimal_panel.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/generated/l10n.dart';

class ThermostatCollapsibleHeader extends StatelessWidget {
  const ThermostatCollapsibleHeader({
    super.key,
    required this.roomName,
    required this.hero,
    required this.heroHeight,
    required this.currentBind,
    required this.sensorsBind,
    required this.chrome,
    this.unit = '°C',
  });

  static const double _heroTopSpacing = 12;
  static const double _temperatureSlotWidth = 88;

  final String roomName;
  final TemperatureMinimalPanel? hero;
  final double heroHeight;
  final String? currentBind;
  final String? sensorsBind;
  final DevicePresenterChrome? chrome;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final hasHero = hero != null;
    final controlState = hasHero
        ? context.select<DeviceSnapshotCubit, Map<String, dynamic>>(
            (cubit) => cubit.state.controlState.data ?? const {},
          )
        : const <String, dynamic>{};
    final reading = _resolveTemperature(controlState);
    final temperatureLabel = '${reading.text}$unit';
    final topPadding = MediaQuery.paddingOf(context).top;
    final expandedHeight =
        kToolbarHeight + (hasHero ? _heroTopSpacing + heroHeight : 0);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return SliverAppBar(
      key: const ValueKey('thermostat-collapsible-header'),
      pinned: true,
      primary: true,
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight,
      collapsedHeight: kToolbarHeight,
      expandedHeight: expandedHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor,
      surfaceTintColor: AppPalette.transparent,
      leading: chrome == null
          ? null
          : IconButton(
              key: const ValueKey('thermostat-open-drawer'),
              onPressed: chrome!.onOpenDrawer,
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              icon: const Icon(Icons.menu_rounded),
            ),
      actions: chrome == null
          ? null
          : [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: chrome!.activityIndicator,
              ),
              IconButton(
                key: const ValueKey('thermostat-open-settings'),
                onPressed: chrome!.onOpenSettings,
                tooltip: S.of(context).Settings,
                icon: const Icon(Icons.settings),
              ),
            ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final minExtent = topPadding + kToolbarHeight;
          final maxExtent = topPadding + expandedHeight;
          final collapseRange = maxExtent - minExtent;
          final collapseProgress = collapseRange <= 0
              ? 1.0
              : (1 -
                      ((constraints.maxHeight - minExtent) / collapseRange)
                          .clamp(0.0, 1.0))
                  .toDouble();
          final disableAnimations =
              MediaQuery.maybeOf(context)?.disableAnimations ?? false;
          final heroVisibility = disableAnimations
              ? (collapseProgress < 0.58 ? 1.0 : 0.0)
              : 1 - _interval(collapseProgress, 0.16, 0.66);
          final temperatureVisibility = !hasHero
              ? 0.0
              : disableAnimations
                  ? (collapseProgress >= 0.78 ? 1.0 : 0.0)
                  : Curves.easeOutCubic.transform(
                      _interval(collapseProgress, 0.68, 0.94),
                    );
          final heroOffset = disableAnimations
              ? 0.0
              : -24 * Curves.easeInCubic.transform(collapseProgress);
          final excludeHero = collapseProgress >= 0.58;

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasHero)
                  Positioned(
                    top: topPadding +
                        kToolbarHeight +
                        _heroTopSpacing +
                        heroOffset,
                    left: 0,
                    right: 0,
                    height: heroHeight,
                    child: Opacity(
                      key: const ValueKey('thermostat-expanded-hero-opacity'),
                      opacity: heroVisibility,
                      child: IgnorePointer(
                        ignoring: excludeHero,
                        child: ExcludeSemantics(
                          excluding: excludeHero,
                          child: RepaintBoundary(child: hero),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: topPadding,
                  left: chrome == null ? 16 : 56,
                  right: chrome == null ? 16 : 104,
                  height: kToolbarHeight,
                  child: IgnorePointer(
                    child: _buildTitle(
                      context,
                      temperatureLabel: temperatureLabel,
                      temperatureVisibility: temperatureVisibility,
                      stale: reading.stale,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle(
    BuildContext context, {
    required String temperatureLabel,
    required double temperatureVisibility,
    required bool stale,
  }) {
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle ??
        Theme.of(context).textTheme.titleLarge;
    final temperatureSlotWidth = _temperatureSlotWidth * temperatureVisibility;
    final semanticsLabel =
        temperatureVisibility > 0.5 ? '$roomName, $temperatureLabel' : roomName;

    return Semantics(
      container: true,
      header: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Positioned.fill(
              right: temperatureSlotWidth,
              child: Center(
                child: Text(
                  roomName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: ClipRect(
                child: SizedBox(
                  width: temperatureSlotWidth,
                  child: Opacity(
                    key: const ValueKey(
                      'thermostat-collapsed-temperature-opacity',
                    ),
                    opacity: temperatureVisibility,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (stale) ...[
                          Container(
                            key: const ValueKey(
                              'thermostat-collapsed-temperature-stale',
                            ),
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppPalette.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            temperatureLabel,
                            key: const ValueKey(
                              'thermostat-collapsed-temperature',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: titleStyle?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  ({String text, bool stale}) _resolveTemperature(
    Map<String, dynamic> controlState,
  ) {
    final rawSensors =
        sensorsBind == null ? null : readBind(controlState, sensorsBind!);
    final sensors = TemperatureSensorsResolver().resolve(rawSensors);

    for (final sensor in sensors) {
      if (sensor.isReference && sensor.hasTemperature) {
        return (
          text: sensor.temp!.toStringAsFixed(1),
          stale: sensor.tempStale,
        );
      }
    }

    final fallback = currentBind == null
        ? null
        : _asNum(readBind(controlState, currentBind!));
    return (
      text: fallback == null ? '—' : fallback.toDouble().toStringAsFixed(1),
      stale: false,
    );
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  double _interval(double value, double start, double end) {
    if (end <= start) return value >= end ? 1 : 0;
    return ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();
  }
}
