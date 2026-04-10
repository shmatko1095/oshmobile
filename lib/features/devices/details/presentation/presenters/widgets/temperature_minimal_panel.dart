import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/utils/temperature_sensors_resolver.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/features/sensors/presentation/models/sensor_editor_entry.dart';
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

  @override
  State<TemperatureMinimalPanel> createState() =>
      _TemperatureMinimalPanelState();
}

class _TemperatureMinimalPanelState extends State<TemperatureMinimalPanel> {
  late final PageController _pageCtrl;
  final TemperatureSensorsResolver _sensorsResolver =
      TemperatureSensorsResolver();
  int _page = 0;
  bool _initialPageResolved = false;
  int? _pendingJumpTarget;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
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

  void _scheduleJumpToPage(int target) {
    if (_pendingJumpTarget == target) return;
    _pendingJumpTarget = target;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final planned = _pendingJumpTarget;
      _pendingJumpTarget = null;
      if (planned == null || !_pageCtrl.hasClients) return;
      _pageCtrl.jumpToPage(planned);
    });
  }

  void _ensureInitialPage(List<TemperatureSensorData> sensors) {
    if (sensors.isEmpty) {
      _initialPageResolved = false;
      _page = 0;
      return;
    }

    final maxIndex = sensors.length - 1;
    if (!_initialPageResolved) {
      final mainIndex = sensors.indexWhere((s) => s.isReference);
      final target = mainIndex >= 0 ? mainIndex : 0;
      _initialPageResolved = true;
      _page = target;
      _scheduleJumpToPage(target);
      return;
    }

    if (_page > maxIndex) {
      _page = maxIndex;
      _scheduleJumpToPage(maxIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlState =
        context.select<DeviceSnapshotCubit, Map<String, dynamic>>(
      (c) => c.state.controlState.data ?? const <String, dynamic>{},
    );

    final currentTarget =
        _asNum(readBind(controlState, widget.currentTargetBind));
    final nextTarget = readBind(controlState, widget.nextTargetBind);
    final nextTime = _nextTargetTime(nextTarget);

    final targetLine = currentTarget == null
        ? null
        : S.of(context).Target('${_fmtNum(currentTarget)}${widget.unit}');
    final nextLine = nextTarget is! Map || nextTime == null
        ? null
        : S.of(context).NextAt(
              '${_fmtNum(_asNum(nextTarget['temp']))}${widget.unit}',
              _fmtTime(context, nextTime),
            );

    final sensors = _sensorsResolver.resolve(
      readBind(controlState, widget.sensorsBind),
    );
    _ensureInitialPage(sensors);
    final fallbackCurrent = _asNum(readBind(controlState, widget.currentBind));

    final content = sensors.isEmpty
        ? _FallbackCard(
            temperatureText: _fmtNum(fallbackCurrent),
            unit: widget.unit,
            borderRadius: widget.borderRadius,
            onTap: widget.onTap,
            targetLine: targetLine,
            nextLine: nextLine,
          )
        : _SensorCarousel(
            pageController: _pageCtrl,
            pageIndex: _page,
            sensors: sensors,
            unit: widget.unit,
            borderRadius: widget.borderRadius,
            onTap: widget.onTap,
            targetLine: targetLine,
            nextLine: nextLine,
            onPageChanged: (nextPage) {
              if (_page == nextPage) return;
              setState(() => _page = nextPage);
            },
            formatNum: _fmtNum,
            onSensorActionTap: widget.onSensorActionTap,
          );

    final panel = Padding(
      padding: widget.padding,
      child: content,
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
}

class _FallbackCard extends StatelessWidget {
  const _FallbackCard({
    required this.temperatureText,
    required this.unit,
    required this.borderRadius,
    required this.onTap,
    required this.targetLine,
    required this.nextLine,
  });

  final String temperatureText;
  final String unit;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? targetLine;
  final String? nextLine;

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
            padding: const EdgeInsets.all(AppPalette.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Temperature',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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
                        fontSize: 78,
                        fontWeight: FontWeight.w300,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        unit,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
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

  @override
  Widget build(BuildContext context) {
    final hasRefSensor = sensors.any((s) => s.isReference);
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pageController,
            padEnds: true,
            itemCount: sensors.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _SensorCard(
                sensor: sensors[index],
                unit: unit,
                borderRadius: borderRadius,
                onTap: onTap,
                targetLine: targetLine,
                nextLine: nextLine,
                showScheduleMeta:
                    hasRefSensor ? sensors[index].isReference : index == 0,
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
                            humidityValid: sensors[index].humidityValid,
                            temp: sensors[index].temp,
                            humidity: sensors[index].humidity,
                          ),
                        ),
              ),
            ),
          ),
        ),
        if (sensors.length > 1) ...[
          const SizedBox(height: 10),
          _Dots(
            count: sensors.length,
            active: pageIndex,
          ),
        ],
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.sensor,
    required this.unit,
    required this.borderRadius,
    required this.onTap,
    required this.targetLine,
    required this.nextLine,
    required this.showScheduleMeta,
    required this.formatNum,
    required this.onActionTap,
  });

  final TemperatureSensorData sensor;
  final String unit;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? targetLine;
  final String? nextLine;
  final bool showScheduleMeta;
  final String Function(num? value, {int fractionDigits}) formatNum;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final hasAnyData = sensor.tempValid || sensor.humidityValid;
    final kindLabel = (sensor.kind ?? '').trim();
    final isMainCard = showScheduleMeta;
    final titleColor = statTitleColor(context);
    final valueColor = statValueColor(context);
    final mutedColor = statMutedColor(context);
    final isDark = isDarkSurface(context);

    return AppSolidCard(
      onTap: onTap,
      radius: borderRadius,
      padding: EdgeInsets.zero,
      backgroundColor: statSurfaceColor(context),
      borderColor: isMainCard
          ? AppPalette.accentPrimary.withValues(alpha: isDark ? 0.24 : 0.2)
          : statBorderColor(context),
      child: Stack(
        children: [
          if (isMainCard) _MainCardAccentLayer(borderRadius: borderRadius),
          Padding(
            padding: const EdgeInsets.all(AppPalette.spaceLg),
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
                          fontSize: 20,
                        ),
                      ),
                    ),
                    _SensorCardAction(sensor: sensor, onTap: onActionTap),
                  ],
                ),
                if (kindLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    kindLabel,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Spacer(),
                if (sensor.tempValid)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatNum(sensor.temp),
                        style: TextStyle(
                          color: valueColor,
                          fontSize: 72,
                          fontWeight: FontWeight.w300,
                          height: 0.95,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          unit,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'No temperature data',
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 12),
                if (sensor.humidityValid)
                  Row(
                    children: [
                      const Icon(Icons.water_drop_rounded,
                          size: 18, color: AppPalette.accentPrimary),
                      const SizedBox(width: 6),
                      Text(
                        '${formatNum(sensor.humidity, fractionDigits: 0)}%',
                        style: TextStyle(
                          color: valueColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  )
                else if (!hasAnyData)
                  Text(
                    'No sensor data',
                    style: TextStyle(
                      color: mutedColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                if (showScheduleMeta)
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
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          padding: EdgeInsets.zero,
          splashRadius: 18,
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
        const SizedBox(height: 10),
        Divider(
          color: isDarkSurface(context)
              ? AppPalette.separator
              : AppPalette.lightBorder,
          thickness: 0.8,
          height: 1,
        ),
        const SizedBox(height: 8),
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
