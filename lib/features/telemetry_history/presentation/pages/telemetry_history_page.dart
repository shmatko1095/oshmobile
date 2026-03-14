import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/telemetry_history/domain/models/telemetry_history_series.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_metric.dart';
import 'package:oshmobile/features/telemetry_history/presentation/models/telemetry_history_range.dart';
import 'package:oshmobile/features/telemetry_history/presentation/widgets/history_line_chart.dart';

class TelemetryHistoryPage extends StatefulWidget {
  const TelemetryHistoryPage({
    super.key,
    required this.metric,
    this.initialRange = TelemetryHistoryRange.h24,
  });

  final TelemetryHistoryMetric metric;
  final TelemetryHistoryRange initialRange;

  @override
  State<TelemetryHistoryPage> createState() => _TelemetryHistoryPageState();
}

class _TelemetryHistoryPageState extends State<TelemetryHistoryPage> {
  late TelemetryHistoryRange _range = widget.initialRange;
  TelemetryHistorySeries? _series;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now().toUtc();
    final from = now.subtract(_range.duration);
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
          await context.read<DeviceFacade>().telemetryHistory.getSeries(
                seriesKey: widget.metric.seriesKey,
                from: from,
                to: now,
                preferredResolution: 'auto',
              );
      if (!mounted) return;
      setState(() {
        _series = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  List<double> _chartValues(TelemetryHistorySeries? series) {
    if (series == null) return const <double>[];
    return switch (widget.metric.kind) {
      TelemetryHistoryMetricKind.numeric => series.points
          .map((p) =>
              p.avgValue ?? p.lastNumericValue ?? p.maxValue ?? p.minValue)
          .whereType<double>()
          .toList(growable: false),
      TelemetryHistoryMetricKind.boolean => series.points
          .map((p) {
            if (p.trueRatio != null) return p.trueRatio!;
            if (p.lastBoolValue != null) return p.lastBoolValue! ? 1.0 : 0.0;
            return null;
          })
          .whereType<double>()
          .toList(growable: false),
    };
  }

  String _fmtValue(double value) {
    if (widget.metric.kind == TelemetryHistoryMetricKind.boolean) {
      return '${(value * 100).round()}%';
    }
    final unit = widget.metric.unit.isEmpty ? '' : ' ${widget.metric.unit}';
    return '${value.toStringAsFixed(1)}$unit';
  }

  Widget _buildStatRow(List<double> values) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final avgValue = values.reduce((a, b) => a + b) / values.length;
    final lastValue = values.last;

    return Row(
      children: [
        Expanded(child: _StatCell(label: 'Min', value: _fmtValue(minValue))),
        const SizedBox(width: 8),
        Expanded(child: _StatCell(label: 'Max', value: _fmtValue(maxValue))),
        const SizedBox(width: 8),
        Expanded(child: _StatCell(label: 'Avg', value: _fmtValue(avgValue))),
        const SizedBox(width: 8),
        Expanded(child: _StatCell(label: 'Last', value: _fmtValue(lastValue))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = _chartValues(_series);
    final isEmpty = !_loading && _error == null && values.isEmpty;

    return Scaffold(
      backgroundColor: AppPalette.canvas,
      appBar: AppBar(
        title: Text(widget.metric.title),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            if (widget.metric.subtitle != null &&
                widget.metric.subtitle!.isNotEmpty) ...[
              Text(
                widget.metric.subtitle!,
                style: const TextStyle(
                  color: AppPalette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  final item = TelemetryHistoryRange.values[index];
                  final selected = _range == item;
                  return ChoiceChip(
                    label: Text(item.label),
                    selected: selected,
                    onSelected: (_) {
                      if (selected) return;
                      setState(() => _range = item);
                      _load();
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: TelemetryHistoryRange.values.length,
              ),
            ),
            const SizedBox(height: 12),
            if (_series != null)
              Text(
                'Resolution: ${_series!.resolution} • Points: ${_series!.points.length}',
                style: const TextStyle(
                  color: AppPalette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 10),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppPalette.surfaceRaised,
                borderRadius: BorderRadius.circular(AppPalette.radiusLg),
                border: Border.all(color: AppPalette.borderSoft),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_error != null)
                        ? _ErrorState(
                            message: _error.toString(),
                            onRetry: _load,
                          )
                        : isEmpty
                            ? const _EmptyState()
                            : HistoryLineChart(
                                values: values,
                                color: widget.metric.kind ==
                                        TelemetryHistoryMetricKind.boolean
                                    ? AppPalette.accentWarning
                                    : AppPalette.accentPrimary,
                              ),
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow(values),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppPalette.surfaceRaised,
        borderRadius: BorderRadius.circular(AppPalette.radiusMd),
        border: Border.all(color: AppPalette.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Failed to load chart',
            style: TextStyle(
              color: AppPalette.textPrimary,
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
            style: const TextStyle(
              color: AppPalette.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onRetry(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No data for selected range',
        style: TextStyle(
          color: AppPalette.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
