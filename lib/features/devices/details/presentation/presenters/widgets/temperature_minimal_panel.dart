import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/utils/temperature_sensors_resolver.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/temperature_history_strip_card.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/features/sensors/presentation/models/sensor_editor_entry.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/temperature_history_preview_cache.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

class TemperatureMinimalPanel extends StatefulWidget {
  const TemperatureMinimalPanel({
    super.key,
    required this.currentBind,
    required this.sensorsBind,
    required this.currentTargetBind,
    required this.nextTargetBind,
    this.onTap,
    this.unit = '°C',
    this.height,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.borderRadius = AppPalette.radiusXl,
    this.onSensorActionTap,
    this.onAddSensorTap,
    this.showHistoryPreview = false,
    this.ultraCompact = false,
    this.historyChartHeight = 104,
    this.onOpenHistory,
    this.historyPreviewCache,
  });

  final String currentBind;
  final String sensorsBind;
  final String currentTargetBind;
  final String nextTargetBind;
  final String unit;
  final double? height;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final ValueChanged<SensorEditorEntry>? onSensorActionTap;
  final VoidCallback? onAddSensorTap;
  final bool showHistoryPreview;
  final bool ultraCompact;
  final double historyChartHeight;
  final OnOpenTemperatureHistory? onOpenHistory;
  final TemperatureHistoryPreviewCache? historyPreviewCache;

  @override
  State<TemperatureMinimalPanel> createState() =>
      _TemperatureMinimalPanelState();
}

class _TemperatureMinimalPanelState extends State<TemperatureMinimalPanel> {
  static const double _viewportFraction = 0.85;

  PageController? _pageCtrl;
  final TemperatureSensorsResolver _sensorsResolver =
      TemperatureSensorsResolver();
  int _page = 0;
  bool _initialPageResolved = false;
  bool _referencePageApplied = false;
  bool _userChangedPage = false;
  int? _pendingJumpTarget;

  @override
  void dispose() {
    _pageCtrl?.dispose();
    super.dispose();
  }

  num? _asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  String _fmtNum(num? v, {int fractionDigits = 1}) {
    if (v == null) return '—';
    final d = v.toDouble();
    if (d.isNaN || d.isInfinite) return '—';
    return d.toStringAsFixed(fractionDigits);
  }

  String _fmtTime(BuildContext context, TimeOfDay t) {
    final alwaysUse24h =
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    return MaterialLocalizations.of(context).formatTimeOfDay(
      t,
      alwaysUse24HourFormat: alwaysUse24h,
    );
  }

  void _replacePageController(int initialPage) {
    final previous = _pageCtrl;
    _pageCtrl = PageController(
      initialPage: initialPage,
      keepPage: false,
      viewportFraction: _viewportFraction,
    );
    if (previous == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous.dispose();
    });
  }

  void _clearPageController() {
    final previous = _pageCtrl;
    _pageCtrl = null;
    if (previous == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous.dispose();
    });
  }

  void _jumpPageController(int target) {
    if (_pageCtrl == null) {
      _replacePageController(target);
    }
    if (_pendingJumpTarget == target) return;
    _pendingJumpTarget = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final planned = _pendingJumpTarget;
      _pendingJumpTarget = null;
      final controller = _pageCtrl;
      if (!mounted ||
          planned == null ||
          controller == null ||
          !controller.hasClients) {
        return;
      }
      controller.jumpToPage(planned);
    });
  }

  void _ensurePageController(
    List<TemperatureSensorData> sensors, {
    required bool hasAddSensorCard,
  }) {
    final pageCount = sensors.length + (hasAddSensorCard ? 1 : 0);
    if (sensors.isEmpty) {
      final shouldResetController = _page != 0 || _pageCtrl == null;
      _initialPageResolved = false;
      _referencePageApplied = false;
      _userChangedPage = false;
      _page = 0;
      if (pageCount == 0) {
        _clearPageController();
        return;
      }
      if (shouldResetController) {
        _replacePageController(0);
      }
      return;
    }

    final maxIndex = pageCount - 1;
    final referenceIndex = sensors.indexWhere((s) => s.isReference);
    if (!_initialPageResolved) {
      final target = referenceIndex >= 0 ? referenceIndex : 0;
      _initialPageResolved = true;
      _referencePageApplied = referenceIndex >= 0;
      _page = target;
      _replacePageController(target);
      if (target != 0) {
        _jumpPageController(target);
      }
      return;
    }

    if (referenceIndex >= 0 && !_referencePageApplied) {
      _referencePageApplied = true;
      if (!_userChangedPage && _page != referenceIndex) {
        _page = referenceIndex;
        _jumpPageController(referenceIndex);
        return;
      }
    }

    if (_page > maxIndex) {
      _page = maxIndex;
      _jumpPageController(maxIndex);
      return;
    }

    if (_pageCtrl == null) {
      _replacePageController(_page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlState =
        context.select<DeviceSnapshotCubit, Map<String, dynamic>>(
      (c) => c.state.controlState.data ?? const <String, dynamic>{},
    );
    final historyCacheNamespace =
        context.select<DeviceSnapshotCubit, String>((c) {
      final device = c.state.device;
      final serial = device.sn.trim();
      if (serial.isNotEmpty) return serial;
      return device.id;
    });

    final currentTarget = readBind(controlState, widget.currentTargetBind);
    final nextTarget = readBind(controlState, widget.nextTargetBind);
    final nextTime = _nextTargetTime(nextTarget);

    final currentSetpointText = _fmtSetpoint(currentTarget);
    final targetLine = currentSetpointText == null
        ? null
        : S.of(context).Target(currentSetpointText);
    final nextLine = nextTarget is! Map || nextTime == null
        ? null
        : S.of(context).NextAt(
              _fmtSetpoint(nextTarget['temp'] ?? nextTarget['setpoint']) ?? '—',
              _fmtTime(context, nextTime),
            );

    final sensors = _sensorsResolver.resolve(
      readBind(controlState, widget.sensorsBind),
    );
    final hasAddSensorCard = widget.onAddSensorTap != null;
    _ensurePageController(
      sensors,
      hasAddSensorCard: hasAddSensorCard,
    );
    final fallbackCurrent = _asNum(readBind(controlState, widget.currentBind));
    final showHistoryPreview = widget.showHistoryPreview && sensors.isNotEmpty;
    final content = sensors.isEmpty && !hasAddSensorCard
        ? _FallbackCard(
            temperatureText: _fmtNum(fallbackCurrent),
            unit: widget.unit,
            borderRadius: widget.borderRadius,
            onTap: widget.onTap,
            targetLine: targetLine,
            nextLine: nextLine,
            ultraCompact: widget.ultraCompact,
          )
        : _SensorCarousel(
            pageController: _pageCtrl!,
            pageIndex: _page,
            sensors: sensors,
            unit: widget.unit,
            borderRadius: widget.borderRadius,
            onTap: widget.onTap,
            targetLine: targetLine,
            nextLine: nextLine,
            showHistoryPreview: showHistoryPreview,
            historyChartHeight: widget.historyChartHeight,
            onOpenHistory: widget.onOpenHistory,
            ultraCompact: widget.ultraCompact,
            onPageChanged: (nextPage) {
              if (_page == nextPage) return;
              setState(() {
                _page = nextPage;
                _userChangedPage = true;
              });
            },
            formatNum: _fmtNum,
            onSensorActionTap: widget.onSensorActionTap,
            onAddSensorTap: widget.onAddSensorTap,
          );

    final panelContent = showHistoryPreview
        ? BlocProvider(
            create: (context) => TemperatureHistoryPreviewCubit(
              seriesReader: context.read<DeviceFacade>().telemetryHistory,
              persistentCache: widget.historyPreviewCache,
              persistentCacheNamespace: historyCacheNamespace,
            ),
            child: content,
          )
        : content;

    final panel = Padding(
      padding: widget.padding,
      child: panelContent,
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height, child: panel);
    }
    return panel;
  }

  TimeOfDay? _nextTargetTime(dynamic raw) {
    if (raw is! Map) return null;
    final hour = _asNum(raw['hour'])?.toInt();
    final minute = _asNum(raw['minute'])?.toInt();
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String? _fmtSetpoint(dynamic raw) {
    if (raw == 'ON' || raw == 'OFF') return raw as String;
    final numeric = _asNum(raw);
    return numeric == null ? null : '${_fmtNum(numeric)}${widget.unit}';
  }
}

class _FallbackCard extends StatelessWidget {
  const _FallbackCard({
    required this.temperatureText,
    required this.unit,
    required this.borderRadius,
    required this.onTap,
    required this.targetLine,
    required this.nextLine,
    required this.ultraCompact,
  });

  final String temperatureText;
  final String unit;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? targetLine;
  final String? nextLine;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final titleColor = statTitleColor(context);
    final valueColor = statValueColor(context);
    final mutedColor = statMutedColor(context);
    final isDark = isDarkSurface(context);

    return AppSolidCard(
      onTap: onTap,
      radius: borderRadius,
      padding: EdgeInsets.zero,
      backgroundColor: statSurfaceColor(context),
      borderColor:
          AppPalette.accentPrimary.withValues(alpha: isDark ? 0.26 : 0.22),
      child: Stack(
        children: [
          _MainCardAccentLayer(borderRadius: borderRadius),
          Padding(
            padding: EdgeInsets.all(
              ultraCompact ? AppPalette.spaceMd : AppPalette.spaceLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temperature',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: ultraCompact ? 14 : 15,
                  ),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      temperatureText,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: ultraCompact ? 52 : 78,
                        fontWeight: FontWeight.w300,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: ultraCompact ? 7 : 12,
                      ),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: ultraCompact ? 18 : 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!ultraCompact)
                  _ScheduleMetaBlock(
                    targetLine: targetLine,
                    nextLine: nextLine,
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCarousel extends StatelessWidget {
  const _SensorCarousel({
    required this.pageController,
    required this.pageIndex,
    required this.sensors,
    required this.unit,
    required this.borderRadius,
    required this.onTap,
    required this.targetLine,
    required this.nextLine,
    required this.onPageChanged,
    required this.formatNum,
    required this.onSensorActionTap,
    required this.onAddSensorTap,
    required this.showHistoryPreview,
    required this.historyChartHeight,
    required this.onOpenHistory,
    required this.ultraCompact,
  });

  final PageController pageController;
  final int pageIndex;
  final List<TemperatureSensorData> sensors;
  final String unit;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? targetLine;
  final String? nextLine;
  final ValueChanged<int> onPageChanged;
  final String Function(num? value, {int fractionDigits}) formatNum;
  final ValueChanged<SensorEditorEntry>? onSensorActionTap;
  final VoidCallback? onAddSensorTap;
  final bool showHistoryPreview;
  final double historyChartHeight;
  final OnOpenTemperatureHistory? onOpenHistory;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final hasRefSensor = sensors.any((s) => s.isReference);
    final itemCount = sensors.length + (onAddSensorTap == null ? 0 : 1);
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pageController,
            padEnds: true,
            itemCount: itemCount,
            onPageChanged: onPageChanged,
            itemBuilder: (_, index) {
              final isAddCard = index >= sensors.length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: isAddCard
                    ? _AddSensorCard(
                        borderRadius: borderRadius,
                        onTap: onAddSensorTap,
                      )
                    : _SensorCard(
                        key: ValueKey(
                          'temperature-sensor-card-${sensors[index].id}',
                        ),
                        sensor: sensors[index],
                        unit: unit,
                        borderRadius: borderRadius,
                        onTap: onTap,
                        targetLine: targetLine,
                        nextLine: nextLine,
                        showScheduleMeta: hasRefSensor
                            ? sensors[index].isReference
                            : index == 0,
                        allSensors: sensors,
                        showHistoryPreview: showHistoryPreview,
                        historyActive: index == pageIndex,
                        historyChartHeight: historyChartHeight,
                        onOpenHistory: onOpenHistory,
                        ultraCompact: ultraCompact,
                        formatNum: formatNum,
                        onActionTap: onSensorActionTap == null
                            ? null
                            : () => onSensorActionTap!(
                                  SensorEditorEntry(
                                    id: sensors[index].id,
                                    name: sensors[index].name,
                                    ref: sensors[index].isReference,
                                    kind: sensors[index].kind,
                                    tempValid: sensors[index].tempValid,
                                    tempStale: sensors[index].tempStale,
                                    humidityValid: sensors[index].humidityValid,
                                    temp: sensors[index].temp,
                                    humidity: sensors[index].humidity,
                                  ),
                                ),
                      ),
              );
            },
          ),
        ),
        if (itemCount > 1) ...[
          const SizedBox(height: 10),
          _Dots(
            count: itemCount,
            active: pageIndex,
          ),
        ],
      ],
    );
  }
}

class _AddSensorCard extends StatelessWidget {
  const _AddSensorCard({
    required this.borderRadius,
    required this.onTap,
  });

  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = statTitleColor(context);
    final valueColor = statValueColor(context);
    final isDark = isDarkSurface(context);

    return AppSolidCard(
      onTap: onTap,
      radius: borderRadius,
      padding: EdgeInsets.zero,
      backgroundColor: statSurfaceColor(context),
      borderColor:
          AppPalette.accentPrimary.withValues(alpha: isDark ? 0.24 : 0.2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppPalette.accentPrimary.withValues(
                  alpha: isDark ? 0.22 : 0.14,
                ),
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 36,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              S.of(context).AddSensor,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    super.key,
    required this.sensor,
    required this.unit,
    required this.borderRadius,
    required this.onTap,
    required this.targetLine,
    required this.nextLine,
    required this.showScheduleMeta,
    required this.allSensors,
    required this.showHistoryPreview,
    required this.historyActive,
    required this.historyChartHeight,
    required this.onOpenHistory,
    required this.formatNum,
    required this.onActionTap,
    required this.ultraCompact,
  });

  final TemperatureSensorData sensor;
  final String unit;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? targetLine;
  final String? nextLine;
  final bool showScheduleMeta;
  final List<TemperatureSensorData> allSensors;
  final bool showHistoryPreview;
  final bool historyActive;
  final double historyChartHeight;
  final OnOpenTemperatureHistory? onOpenHistory;
  final String Function(num? value, {int fractionDigits}) formatNum;
  final VoidCallback? onActionTap;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final isMainCard = showScheduleMeta;
    final isDark = isDarkSurface(context);

    return AppSolidCard(
      radius: borderRadius,
      padding: EdgeInsets.zero,
      backgroundColor: statSurfaceColor(context),
      borderColor: isMainCard
          ? AppPalette.accentPrimary.withValues(alpha: isDark ? 0.24 : 0.2)
          : statBorderColor(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            if (isMainCard && !showHistoryPreview)
              _MainCardAccentLayer(borderRadius: borderRadius),
            if (showHistoryPreview)
              Positioned.fill(
                child: TemperatureSensorHistoryBackdrop(
                  key: ValueKey(
                    'temperature-history-backdrop-${sensor.id}',
                  ),
                  sensor: sensor,
                  active: historyActive,
                  padding: const EdgeInsets.fromLTRB(0, 76, 0, 0),
                ),
              ),
            if (showHistoryPreview) const _HistoryBackdropReadabilityLayer(),
            Positioned.fill(
              child: _SensorTemperaturePane(
                sensor: sensor,
                unit: unit,
                borderRadius: borderRadius,
                onTap: onTap,
                targetLine: targetLine,
                nextLine: nextLine,
                showScheduleMeta: showScheduleMeta,
                compact: showHistoryPreview,
                ultraCompact: ultraCompact,
                formatNum: formatNum,
                onActionTap: onActionTap,
              ),
            ),
            if (onOpenHistory != null)
              Positioned(
                right: 14,
                bottom: 12,
                child: _SensorHistoryAction(
                  sensor: sensor,
                  onTap: () => onOpenHistory!(
                    temperatureHistorySensorRefs(allSensors),
                    sensor.id,
                    sensor.name,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryBackdropReadabilityLayer extends StatelessWidget {
  const _HistoryBackdropReadabilityLayer();

  @override
  Widget build(BuildContext context) {
    final surface = statSurfaceColor(context);
    final isDark = isDarkSurface(context);

    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                surface.withValues(alpha: isDark ? 0.86 : 0.82),
                surface.withValues(alpha: isDark ? 0.34 : 0.36),
                surface.withValues(alpha: isDark ? 0.0 : 0.06),
              ],
              stops: const [0.0, 0.46, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _SensorHistoryAction extends StatelessWidget {
  const _SensorHistoryAction({
    required this.sensor,
    required this.onTap,
  });

  final TemperatureSensorData sensor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final surface = statSurfaceColor(context);
    final isDark = isDarkSurface(context);

    return Semantics(
      button: true,
      label: '${s.TelemetryHistoryPreviewTitle24h}, ${sensor.name}',
      hint: s.TelemetryHistoryPreviewOpenHint,
      child: Tooltip(
        message: s.TelemetryHistoryPreviewOpenHint,
        child: Material(
          color: AppPalette.transparent,
          child: InkWell(
            key: ValueKey('temperature-history-preview-${sensor.id}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: surface.withValues(alpha: isDark ? 0.72 : 0.82),
                borderRadius: BorderRadius.circular(AppPalette.radiusPill),
                border: Border.all(
                  color: AppPalette.accentPrimary.withValues(
                    alpha: isDark ? 0.24 : 0.18,
                  ),
                ),
              ),
              child: Icon(
                Icons.show_chart_rounded,
                size: 19,
                color: AppPalette.accentPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SensorTemperaturePane extends StatelessWidget {
  const _SensorTemperaturePane({
    required this.sensor,
    required this.unit,
    required this.borderRadius,
    required this.onTap,
    required this.targetLine,
    required this.nextLine,
    required this.showScheduleMeta,
    required this.compact,
    required this.formatNum,
    required this.onActionTap,
    required this.ultraCompact,
  });

  final TemperatureSensorData sensor;
  final String unit;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? targetLine;
  final String? nextLine;
  final bool showScheduleMeta;
  final bool compact;
  final String Function(num? value, {int fractionDigits}) formatNum;
  final VoidCallback? onActionTap;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final titleColor = statTitleColor(context);
    final valueColor = statValueColor(context);
    final mutedColor = statMutedColor(context);
    final valueFontSize = ultraCompact ? 52.0 : (compact ? 76.0 : 72.0);
    final unitFontSize = valueFontSize;
    final contentPadding = EdgeInsets.all(
      ultraCompact ? AppPalette.spaceMd : AppPalette.spaceLg,
    );

    final content = Padding(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sensor.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                    fontSize: ultraCompact ? 16 : (compact ? 18 : 20),
                  ),
                ),
              ),
              _SensorCardAction(sensor: sensor, onTap: onActionTap),
            ],
          ),
          if (ultraCompact)
            const Spacer()
          else if (compact)
            const SizedBox(height: 62)
          else
            const Spacer(),
          _SensorReadingsRow(
            sensor: sensor,
            unit: unit,
            valueColor: valueColor,
            unitColor: titleColor,
            humidityColor: mutedColor,
            valueFontSize: valueFontSize,
            unitFontSize: unitFontSize,
            compact: compact || ultraCompact,
            formatNum: formatNum,
          ),
          SizedBox(height: ultraCompact ? 4 : (compact ? 8 : 12)),
          if (showScheduleMeta && !ultraCompact)
            _ScheduleMetaBlock(
              targetLine: targetLine,
              nextLine: nextLine,
              titleColor: titleColor,
              mutedColor: mutedColor,
            ),
          if (compact || ultraCompact) const Spacer(),
        ],
      ),
    );

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    );
  }
}

class _SensorReadingsRow extends StatelessWidget {
  const _SensorReadingsRow({
    required this.sensor,
    required this.unit,
    required this.valueColor,
    required this.unitColor,
    required this.humidityColor,
    required this.valueFontSize,
    required this.unitFontSize,
    required this.compact,
    required this.formatNum,
  });

  final TemperatureSensorData sensor;
  final String unit;
  final Color valueColor;
  final Color unitColor;
  final Color humidityColor;
  final double valueFontSize;
  final double unitFontSize;
  final bool compact;
  final String Function(num? value, {int fractionDigits}) formatNum;

  @override
  Widget build(BuildContext context) {
    final temperatureText =
        sensor.hasTemperature ? formatNum(sensor.temp) : '--';
    final temperatureStyle = TextStyle(
      color: valueColor,
      fontSize: valueFontSize,
      fontWeight: FontWeight.w300,
      height: 0.95,
    );

    final humidityStyle = TextStyle(
      color: humidityColor,
      fontSize: compact ? 17 : 19,
      fontWeight: FontWeight.w700,
      height: 1.1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                temperatureText,
                style: temperatureStyle,
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: unitColor,
                  fontSize: unitFontSize,
                  fontWeight: FontWeight.w300,
                  height: 0.95,
                ),
              ),
              if (sensor.hasTemperature && sensor.tempStale) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: EdgeInsets.only(bottom: compact ? 17 : 18),
                  child: Container(
                    key: ValueKey(
                      'temperature-stale-indicator-${sensor.id}',
                    ),
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppPalette.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (sensor.humidityValid) SizedBox(height: compact ? 2 : 4),
        if (sensor.humidityValid)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop_rounded,
                size: compact ? 16 : 18,
                color: AppPalette.accentPrimary.withValues(alpha: 0.82),
              ),
              const SizedBox(width: 4),
              Text(
                '${formatNum(sensor.humidity, fractionDigits: 0)}%',
                style: humidityStyle,
              ),
            ],
          ),
      ],
    );
  }
}

class _SensorCardAction extends StatelessWidget {
  const _SensorCardAction({
    required this.sensor,
    required this.onTap,
  });

  final TemperatureSensorData sensor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final valueColor = statValueColor(context);
    final isDark = isDarkSurface(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sensor.isReference) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppPalette.accentPrimary.withValues(
                alpha: isDark ? 0.22 : 0.14,
              ),
              borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            ),
            child: Text(
              S.of(context).SensorMainLabel,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        IconButton(
          onPressed: onTap,
          tooltip: S.of(context).SensorMoreActions,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          padding: EdgeInsets.zero,
          splashRadius: 22,
          icon: Icon(
            Icons.more_horiz_rounded,
            size: 20,
            color: statTitleColor(context),
          ),
        ),
      ],
    );
  }
}

class _MainCardAccentLayer extends StatelessWidget {
  const _MainCardAccentLayer({
    required this.borderRadius,
  });

  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppPalette.accentPrimary.withValues(alpha: 0.14),
                AppPalette.accentPrimary.withValues(alpha: 0.06),
                AppPalette.transparent,
              ],
              stops: const [0.0, 0.42, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleMetaBlock extends StatelessWidget {
  const _ScheduleMetaBlock({
    required this.targetLine,
    required this.nextLine,
    required this.titleColor,
    required this.mutedColor,
  });

  final String? targetLine;
  final String? nextLine;
  final Color titleColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    if (targetLine == null && nextLine == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        if (targetLine != null)
          Text(
            targetLine!,
            style: TextStyle(
              color: titleColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (nextLine != null) ...[
          const SizedBox(height: 2),
          Text(
            nextLine!,
            style: TextStyle(
              color: mutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.active,
  });

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppPalette.motionFast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            width: i == active ? 16 : 6,
            decoration: BoxDecoration(
              color: i == active
                  ? AppPalette.accentPrimary
                  : statMutedColor(context).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(AppPalette.radiusPill),
            ),
          ),
      ],
    );
  }
}
