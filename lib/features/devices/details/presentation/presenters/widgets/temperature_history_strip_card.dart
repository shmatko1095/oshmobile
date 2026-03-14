import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_cubit.dart';
import 'package:oshmobile/features/telemetry_history/presentation/cubit/temperature_history_preview_state.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_sensor.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_line_chart.dart';

typedef OnOpenTemperatureHistory = void Function(
  List<TelemetryHistorySensor> sensors,
  String sensorId,
  String sensorName,
);

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
    return BlocProvider(
      create: (context) => TemperatureHistoryPreviewCubit(
        telemetryHistoryApi: context.read<DeviceFacade>().telemetryHistory,
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
  bool _ensureScheduled = false;
  String? _scheduledSeriesKey;
  final List<String> _sensorOrder = <String>[];

  List<_SensorTarget> _resolveSensors(dynamic raw) {
    if (raw is! List) {
      _sensorOrder.clear();
      return const <_SensorTarget>[];
    }

    final sensors = <_SensorTarget>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final id = (map['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;

      final nameRaw = (map['name'] ?? '').toString().trim();
      final name = nameRaw.isEmpty ? id : nameRaw;
      final ref = map['ref'] == true;
      final tempValid = map['temp_valid'] == true;
      sensors.add(
          _SensorTarget(id: id, name: name, ref: ref, tempValid: tempValid));
    }

    if (sensors.isEmpty) {
      _sensorOrder.clear();
      return const <_SensorTarget>[];
    }

    final incomingIds = sensors.map((s) => s.id).toSet();
    _sensorOrder.removeWhere((id) => !incomingIds.contains(id));

    final knownIds = _sensorOrder.toSet();
    for (final sensor in sensors) {
      if (!knownIds.contains(sensor.id)) {
        _sensorOrder.add(sensor.id);
        knownIds.add(sensor.id);
      }
    }

    final byId = <String, _SensorTarget>{
      for (final sensor in sensors) sensor.id: sensor,
    };
    return _sensorOrder
        .map((id) => byId[id])
        .whereType<_SensorTarget>()
        .toList(growable: false);
  }

  _SensorTarget? _preferredPreviewSensor(List<_SensorTarget> sensors) {
    if (sensors.isEmpty) return null;

    final refValid = sensors.where((s) => s.ref && s.tempValid);
    if (refValid.isNotEmpty) {
      return refValid.first;
    }

    final firstValid = sensors.where((s) => s.tempValid);
    if (firstValid.isNotEmpty) {
      return firstValid.first;
    }

    return sensors.first;
  }

  List<TelemetryHistorySensor> _toHistorySensors(List<_SensorTarget> sensors) {
    return sensors
        .map(
          (sensor) => TelemetryHistorySensor(
            id: sensor.id,
            name: sensor.name,
            ref: sensor.ref,
          ),
        )
        .toList(growable: false);
  }

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
    final cardHeight = widget.height ?? widget.chartHeight;
    final effectiveChartHeight = math.min(widget.chartHeight, cardHeight);

    final controlState =
        context.select<DeviceSnapshotCubit, Map<String, dynamic>>(
      (c) => c.state.controlState.data ?? const <String, dynamic>{},
    );
    final sensorsRaw = readBind(controlState, widget.sensorsBind);
    final sensors = _resolveSensors(sensorsRaw);
    final target = _preferredPreviewSensor(sensors);

    if (target == null) {
      return AppSolidCard(
        radius: AppPalette.radiusXl,
        backgroundColor: AppPalette.surfaceRaised,
        borderColor: AppPalette.borderSoft,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: cardHeight,
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Temperature trend (24h): no sensor data',
              style: TextStyle(
                color: AppPalette.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    final seriesKey = 'climate_sensors.${target.id}.temp';
    if (context.read<TemperatureHistoryPreviewCubit>().shouldLoad(seriesKey)) {
      _scheduleEnsureLoaded(seriesKey);
    }
    final preview = context.select<TemperatureHistoryPreviewCubit,
        TemperatureHistoryPreviewEntry?>(
      (cubit) => cubit.state.entryOf(seriesKey),
    );
    final values = preview?.values ?? const <double>[];
    final hasData = values.isNotEmpty;
    final loading = preview == null ||
        preview.status == TemperatureHistoryPreviewStatus.loading;
    final lastValueText = preview?.lastValue?.toStringAsFixed(1);

    return AppSolidCard(
      radius: AppPalette.radiusXl,
      backgroundColor: AppPalette.surfaceRaised,
      borderColor: AppPalette.borderSoft,
      padding: EdgeInsets.zero,
      onTap: () => widget.onOpenHistory
          ?.call(_toHistorySensors(sensors), target.id, target.name),
      child: SizedBox(
        height: cardHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppPalette.radiusXl),
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
                            color: AppPalette.accentPrimary,
                            strokeWidth: 1.8,
                            fill: true,
                            showGrid: false,
                          )
                        : const Center(
                            child: Text(
                              '—',
                              style: TextStyle(
                                color: AppPalette.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
              ),
              Positioned(
                left: 10,
                top: 8,
                right: 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temperature trend (24h)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppPalette.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            target.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppPalette.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lastValueText == null ? '—' : '$lastValueText°C',
                      style: const TextStyle(
                        color: AppPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorTarget {
  const _SensorTarget({
    required this.id,
    required this.name,
    required this.ref,
    required this.tempValid,
  });

  final String id;
  final String name;
  final bool ref;
  final bool tempValid;
}
