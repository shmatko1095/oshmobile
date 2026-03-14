import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_line_chart.dart';

class TemperatureHistoryStripCard extends StatefulWidget {
  const TemperatureHistoryStripCard({
    super.key,
    required this.sensorsBind,
    this.onOpenHistory,
  });

  final String sensorsBind;
  final void Function(String sensorId, String sensorName)? onOpenHistory;

  @override
  State<TemperatureHistoryStripCard> createState() =>
      _TemperatureHistoryStripCardState();
}

class _TemperatureHistoryStripCardState
    extends State<TemperatureHistoryStripCard> {
  final Map<String, Future<_PreviewData>> _previewBySeriesKey = {};

  _SensorTarget? _resolveSensorTarget(dynamic raw) {
    if (raw is! List) {
      return null;
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

    if (sensors.isEmpty) return null;
    final refValid =
        sensors.where((s) => s.ref && s.tempValid).toList(growable: false);
    if (refValid.isNotEmpty) return refValid.first;

    final firstValid =
        sensors.where((s) => s.tempValid).toList(growable: false);
    if (firstValid.isNotEmpty) return firstValid.first;

    return sensors.first;
  }

  Future<_PreviewData> _loadPreview(String seriesKey) async {
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(hours: 24));
    final series =
        await context.read<DeviceFacade>().telemetryHistory.getSeries(
              seriesKey: seriesKey,
              from: from,
              to: now,
              preferredResolution: 'auto',
            );
    return _PreviewData.fromSeries(series);
  }

  @override
  Widget build(BuildContext context) {
    final controlState =
        context.select<DeviceSnapshotCubit, Map<String, dynamic>>(
      (c) => c.state.controlState.data ?? const <String, dynamic>{},
    );
    final sensorsRaw = readBind(controlState, widget.sensorsBind);
    final target = _resolveSensorTarget(sensorsRaw);

    if (target == null) {
      return AppSolidCard(
        radius: AppPalette.radiusXl,
        backgroundColor: AppPalette.surfaceRaised,
        borderColor: AppPalette.borderSoft,
        child: const SizedBox(
          height: 72,
          child: Align(
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
    final previewFuture = _previewBySeriesKey.putIfAbsent(
      seriesKey,
      () => _loadPreview(seriesKey),
    );

    return AppSolidCard(
      radius: AppPalette.radiusXl,
      backgroundColor: AppPalette.surfaceRaised,
      borderColor: AppPalette.borderSoft,
      onTap: () => widget.onOpenHistory?.call(target.id, target.name),
      child: SizedBox(
        height: 82,
        child: FutureBuilder<_PreviewData>(
          future: previewFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final values = data?.values ?? const <double>[];
            final hasData = values.isNotEmpty;
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                    data == null;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temperature trend (24h)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        target.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 132,
                  height: 52,
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
                const SizedBox(width: 12),
                Text(
                  data == null ? '—' : '${data.lastValue.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    color: AppPalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          },
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

class _PreviewData {
  const _PreviewData({
    required this.values,
    required this.lastValue,
  });

  final List<double> values;
  final double lastValue;

  factory _PreviewData.fromSeries(TelemetryHistorySeries series) {
    final values = series.points
        .map(
            (p) => p.avgValue ?? p.lastNumericValue ?? p.maxValue ?? p.minValue)
        .whereType<double>()
        .toList(growable: false);
    if (values.isEmpty) {
      return const _PreviewData(values: <double>[], lastValue: 0);
    }
    return _PreviewData(values: values, lastValue: values.last);
  }
}
