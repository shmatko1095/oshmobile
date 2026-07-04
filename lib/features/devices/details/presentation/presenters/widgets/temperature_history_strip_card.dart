import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/models/device_temperature_sensor_ref.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/utils/temperature_sensors_resolver.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/features/telemetry_history/domain/contracts/temperature_history_preview_cache.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_line_chart.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';

typedef OnOpenTemperatureHistory = void Function(
  List<DeviceTemperatureSensorRef> sensors,
  String sensorId,
  String sensorName,
);

List<DeviceTemperatureSensorRef> temperatureHistorySensorRefs(
  List<TemperatureSensorData> sensors,
) {
  return sensors
      .map(
        (sensor) => DeviceTemperatureSensorRef(
          id: sensor.id,
          name: sensor.name,
          isReference: sensor.isReference,
        ),
      )
      .toList(growable: false);
}

class TemperatureHistoryStripCard extends StatelessWidget {
  const TemperatureHistoryStripCard({
    super.key,
    required this.sensorsBind,
    this.height,
    this.chartHeight = 88,
    this.onOpenHistory,
  });

  final String sensorsBind;
  final double? height;
  final double chartHeight;
  final OnOpenTemperatureHistory? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final cacheNamespace = context.select<DeviceSnapshotCubit, String>((c) {
      final device = c.state.device;
      final serial = device.sn.trim();
      if (serial.isNotEmpty) return serial;
      return device.id;
    });

    return BlocProvider(
      create: (context) => TemperatureHistoryPreviewCubit(
        seriesReader: context.read<DeviceFacade>().telemetryHistory,
        persistentCache: _historyPreviewCacheOrNull(),
        persistentCacheNamespace: cacheNamespace,
      ),
      child: _TemperatureHistoryStripCardView(
        sensorsBind: sensorsBind,
        height: height,
        chartHeight: chartHeight,
        onOpenHistory: onOpenHistory,
      ),
    );
  }
}

TemperatureHistoryPreviewCache? _historyPreviewCacheOrNull() {
  if (!locator.isRegistered<TemperatureHistoryPreviewCache>()) return null;
  return locator<TemperatureHistoryPreviewCache>();
}

class TemperatureSensorHistoryPreview extends StatefulWidget {
  const TemperatureSensorHistoryPreview({
    super.key,
    required this.sensor,
    required this.sensors,
    required this.active,
    required this.height,
    this.chartHeight,
    this.onOpenHistory,
    this.showTitle = true,
    this.showSensorName = false,
    this.showTopDivider = false,
    this.borderRadius = AppPalette.radiusLg,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 10),
  });

  final TemperatureSensorData sensor;
  final List<TemperatureSensorData> sensors;
  final bool active;
  final double height;
  final double? chartHeight;
  final OnOpenTemperatureHistory? onOpenHistory;
  final bool showTitle;
  final bool showSensorName;
  final bool showTopDivider;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  State<TemperatureSensorHistoryPreview> createState() =>
      _TemperatureSensorHistoryPreviewState();
}

class _TemperatureSensorHistoryPreviewState
    extends State<TemperatureSensorHistoryPreview> {
  bool _ensureScheduled = false;
  String? _scheduledSeriesKey;

  String get _seriesKey => 'climate_sensors.${widget.sensor.id}.temp';

  void _scheduleEnsureLoaded(String seriesKey) {
    _scheduledSeriesKey = seriesKey;
    if (_ensureScheduled) return;
    _ensureScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureScheduled = false;
      final key = _scheduledSeriesKey;
      _scheduledSeriesKey = null;
      if (!mounted || key == null || key.isEmpty) return;
      context
          .read<TemperatureHistoryPreviewCubit>()
          .ensureLoaded(seriesKey: key);
    });
  }

  void _openHistory() {
    widget.onOpenHistory?.call(
      temperatureHistorySensorRefs(widget.sensors),
      widget.sensor.id,
      widget.sensor.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mutedColor = statMutedColor(context);
    final titleColor = statValueColor(context);
    final subtitleColor = statTitleColor(context);
    final effectiveChartHeight =
        math.min(widget.chartHeight ?? widget.height, widget.height);
    final seriesKey = _seriesKey;

    if (widget.active &&
        context.read<TemperatureHistoryPreviewCubit>().shouldLoad(seriesKey)) {
      _scheduleEnsureLoaded(seriesKey);
    }

    final preview = context.select<TemperatureHistoryPreviewCubit,
        TemperatureHistoryPreviewEntry?>(
      (cubit) => cubit.state.entryOf(seriesKey),
    );
    final values = preview?.values ?? const <double>[];
    final timestamps = preview?.timestamps;
    final hasData = values.isNotEmpty;
    final loading = widget.active &&
        (preview == null ||
            preview.status == TemperatureHistoryPreviewStatus.loading);
    final showHeader = widget.showTitle || widget.showSensorName;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: widget.showTopDivider
            ? Border(
                top: BorderSide(
                  color: isDarkSurface(context)
                      ? AppPalette.separator
                      : AppPalette.lightBorder,
                  width: 0.8,
                ),
              )
            : null,
      ),
      child: Semantics(
        button: widget.onOpenHistory != null,
        label: '${s.TelemetryHistoryPreviewTitle24h}, ${widget.sensor.name}',
        hint: widget.onOpenHistory == null
            ? null
            : s.TelemetryHistoryPreviewOpenHint,
        child: InkWell(
          onTap: widget.onOpenHistory == null ? null : _openHistory,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: SizedBox(
            key: ValueKey('temperature-history-preview-${widget.sensor.id}'),
            height: widget.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: effectiveChartHeight,
                    child: loading
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : hasData
                            ? HistoryLineChart(
                                values: values,
                                timestamps: timestamps,
                                windowStart: preview?.windowStart,
                                windowEnd: preview?.windowEnd,
                                color: AppPalette.accentPrimary,
                                strokeWidth: 1.8,
                                fill: true,
                                showGrid: false,
                              )
                            : Center(
                                child: Text(
                                  '—',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                  ),
                  if (showHeader)
                    Positioned(
                      left: widget.padding.left,
                      top: widget.padding.top,
                      right: widget.padding.right,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.showTitle)
                                  Text(
                                    s.TelemetryHistoryPreviewTitle24h,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                if (widget.showSensorName) ...[
                                  if (widget.showTitle)
                                    const SizedBox(height: 2),
                                  Text(
                                    widget.sensor.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: subtitleColor,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TemperatureSensorHistoryBackdrop extends StatefulWidget {
  const TemperatureSensorHistoryBackdrop({
    super.key,
    required this.sensor,
    required this.active,
    this.padding = const EdgeInsets.fromLTRB(0, 72, 0, 0),
  });

  final TemperatureSensorData sensor;
  final bool active;
  final EdgeInsets padding;

  @override
  State<TemperatureSensorHistoryBackdrop> createState() =>
      _TemperatureSensorHistoryBackdropState();
}

class _TemperatureSensorHistoryBackdropState
    extends State<TemperatureSensorHistoryBackdrop> {
  bool _ensureScheduled = false;
  String? _scheduledSeriesKey;

  String get _seriesKey => 'climate_sensors.${widget.sensor.id}.temp';

  void _scheduleEnsureLoaded(String seriesKey) {
    _scheduledSeriesKey = seriesKey;
    if (_ensureScheduled) return;
    _ensureScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureScheduled = false;
      final key = _scheduledSeriesKey;
      _scheduledSeriesKey = null;
      if (!mounted || key == null || key.isEmpty) return;
      context
          .read<TemperatureHistoryPreviewCubit>()
          .ensureLoaded(seriesKey: key);
    });
  }

  @override
  Widget build(BuildContext context) {
    final seriesKey = _seriesKey;
    if (widget.active &&
        context.read<TemperatureHistoryPreviewCubit>().shouldLoad(seriesKey)) {
      _scheduleEnsureLoaded(seriesKey);
    }

    final preview = context.select<TemperatureHistoryPreviewCubit,
        TemperatureHistoryPreviewEntry?>(
      (cubit) => cubit.state.entryOf(seriesKey),
    );
    final values = preview?.values ?? const <double>[];
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animationDuration =
        disableAnimations ? Duration.zero : const Duration(milliseconds: 500);
    final chart = values.isEmpty
        ? const SizedBox.expand(
            key: ValueKey('temperature-history-backdrop-empty'),
          )
        : CustomPaint(
            key: ValueKey(
              'temperature-history-backdrop-chart-${widget.sensor.id}-'
              '${values.length}-${preview?.updatedAt?.microsecondsSinceEpoch}',
            ),
            painter: _TemperatureHistoryBackdropPainter(
              values: values,
              color: AppPalette.accentPrimary,
              isDark: isDarkSurface(context),
            ),
            child: const SizedBox.expand(),
          );

    return IgnorePointer(
      child: Padding(
        padding: widget.padding,
        child: AnimatedSwitcher(
          duration: animationDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: chart,
        ),
      ),
    );
  }
}

class _TemperatureHistoryBackdropPainter extends CustomPainter {
  const _TemperatureHistoryBackdropPainter({
    required this.values,
    required this.color,
    required this.isDark,
  });

  final List<double> values;
  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    final points = _pointsFor(size);
    if (points.isEmpty) return;

    final area = _smoothAreaPath(points, size);

    final fillColor = Color.lerp(
          color,
          isDark ? AppPalette.black : AppPalette.lightTextPrimary,
          isDark ? 0.10 : 0.24,
        ) ??
        color;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          fillColor.withValues(alpha: isDark ? 0.70 : 0.52),
          fillColor.withValues(alpha: isDark ? 0.38 : 0.28),
          fillColor.withValues(alpha: isDark ? 0.13 : 0.10),
          fillColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.48, 0.78, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(area, fillPaint);
  }

  List<Offset> _pointsFor(Size size) {
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final rawRange = maxValue - minValue;
    final range = rawRange.abs() < 0.01 ? 1.0 : rawRange;
    final minY = minValue - (rawRange.abs() < 0.01 ? 0.5 : 0);
    final top = size.height * 0.16;
    final bottom = size.height * 0.90;
    final drawableHeight = bottom - top;
    final xStep = values.length <= 1 ? 0.0 : size.width / (values.length - 1);

    return <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          values.length <= 1 ? size.width / 2 : i * xStep,
          bottom -
              ((values[i] - minY) / range).clamp(0.0, 1.0) * drawableHeight,
        ),
    ];
  }

  Path _smoothAreaPath(List<Offset> points, Size size) {
    final path = Path()
      ..moveTo(points.first.dx, size.height)
      ..lineTo(points.first.dx, points.first.dy);

    if (points.length == 1) {
      path
        ..lineTo(points.first.dx + 0.01, points.first.dy)
        ..lineTo(points.first.dx + 0.01, size.height)
        ..close();
      return path;
    }

    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final mid = Offset(
        (previous.dx + current.dx) / 2,
        (previous.dy + current.dy) / 2,
      );
      path.quadraticBezierTo(previous.dx, previous.dy, mid.dx, mid.dy);
    }

    path
      ..lineTo(points.last.dx, points.last.dy)
      ..lineTo(points.last.dx, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _TemperatureHistoryBackdropPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

class _TemperatureHistoryStripCardView extends StatefulWidget {
  const _TemperatureHistoryStripCardView({
    required this.sensorsBind,
    required this.height,
    required this.chartHeight,
    required this.onOpenHistory,
  });

  final String sensorsBind;
  final double? height;
  final double chartHeight;
  final OnOpenTemperatureHistory? onOpenHistory;

  @override
  State<_TemperatureHistoryStripCardView> createState() =>
      _TemperatureHistoryStripCardViewState();
}

class _TemperatureHistoryStripCardViewState
    extends State<_TemperatureHistoryStripCardView> {
  final TemperatureSensorsResolver _sensorsResolver =
      TemperatureSensorsResolver();

  TemperatureSensorData? _preferredPreviewSensor(
    List<TemperatureSensorData> sensors,
  ) {
    if (sensors.isEmpty) return null;

    final refValid = sensors.where((s) => s.isReference && s.tempValid);
    if (refValid.isNotEmpty) {
      return refValid.first;
    }

    final firstValid = sensors.where((s) => s.tempValid);
    if (firstValid.isNotEmpty) {
      return firstValid.first;
    }

    return sensors.first;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cardHeight = widget.height ?? widget.chartHeight;
    final effectiveChartHeight = math.min(widget.chartHeight, cardHeight);
    final mutedColor = statMutedColor(context);

    final controlState =
        context.select<DeviceSnapshotCubit, Map<String, dynamic>>(
      (c) => c.state.controlState.data ?? const <String, dynamic>{},
    );
    final sensorsRaw = readBind(controlState, widget.sensorsBind);
    final sensors = _sensorsResolver.resolve(sensorsRaw);
    final target = _preferredPreviewSensor(sensors);

    return AppSolidCard(
      radius: AppPalette.radiusXl,
      backgroundColor: statSurfaceColor(context),
      borderColor: statBorderColor(context),
      padding: EdgeInsets.zero,
      child: target == null
          ? SizedBox(
              height: cardHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  s.TelemetryHistoryPreviewNoSensorData,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          : TemperatureSensorHistoryPreview(
              sensor: target,
              sensors: sensors,
              active: true,
              height: cardHeight,
              chartHeight: effectiveChartHeight,
              onOpenHistory: widget.onOpenHistory,
              showSensorName: true,
              borderRadius: AppPalette.radiusXl,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            ),
    );
  }
}
