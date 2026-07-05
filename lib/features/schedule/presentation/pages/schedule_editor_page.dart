import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/schedule/domain/models/calendar_snapshot.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/pages/manual_temperature_page.dart';
import 'package:oshmobile/features/schedule/presentation/pages/manual_time_page.dart';
import 'package:oshmobile/features/schedule/presentation/utils/schedule_point_defaults.dart';
import 'package:oshmobile/features/schedule/presentation/widgets/schedule_editor_widgets.dart';
import 'package:oshmobile/generated/l10n.dart';

class ScheduleEditorPage extends StatefulWidget {
  const ScheduleEditorPage({
    super.key,
    required this.title,
    this.mode,
  });

  final String title;
  final CalendarMode? mode;

  @override
  State<ScheduleEditorPage> createState() => _ScheduleEditorPageState();
}

class _ScheduleEditorPageState extends State<ScheduleEditorPage> {
  int _filterMask = 0;

  bool _passesFilter(int mask) =>
      _filterMask == 0 ? true : (mask & _filterMask) != 0;

  CalendarMode _targetMode(CalendarSnapshot schedule) =>
      widget.mode ?? schedule.mode;

  void _patchPoint(
    DeviceFacade facade,
    CalendarSnapshot schedule,
    CalendarMode mode,
    int index,
    SchedulePoint point,
  ) {
    final current = List<SchedulePoint>.from(schedule.pointsFor(mode));
    if (index < 0 || index >= current.length) return;
    current[index] = point;
    facade.schedule.patchList(mode, current);
  }

  void _removePoint(
    DeviceFacade facade,
    CalendarSnapshot schedule,
    CalendarMode mode,
    int index,
  ) {
    final current = List<SchedulePoint>.from(schedule.pointsFor(mode));
    if (index < 0 || index >= current.length) return;
    current.removeAt(index);
    facade.schedule.patchList(mode, current);
  }

  void _addPoint(
    DeviceFacade facade,
    CalendarSnapshot schedule,
    CalendarMode mode,
  ) {
    final current = List<SchedulePoint>.from(schedule.pointsFor(mode));
    current.add(makeDefaultSchedulePoint(current, mode));
    facade.schedule.patchList(mode, current);
  }

  Future<void> _openTimeEditor({
    required BuildContext context,
    required DeviceFacade facade,
    required CalendarSnapshot schedule,
    required CalendarMode targetMode,
    required int index,
    required SchedulePoint point,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: OshAnalyticsScreens.manualTime,
        ),
        builder: (_) => ManualTimePage(
          title: S.of(context).time,
          initial: point.time,
          onSave: (value) => _patchPoint(
            facade,
            schedule,
            targetMode,
            index,
            point.copyWith(time: value),
          ),
        ),
      ),
    );
  }

  Future<void> _openTemperatureEditor({
    required BuildContext context,
    required DeviceFacade facade,
    required CalendarSnapshot schedule,
    required CalendarMode targetMode,
    required int index,
    required SchedulePoint point,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(
          name: OshAnalyticsScreens.manualTemperature,
        ),
        builder: (_) => ManualTemperaturePage(
          title: S.of(context).SetTemperature,
          initial: point.temp,
          onSave: (value) {
            final rounded = double.parse(value.toStringAsFixed(1));
            _patchPoint(
              facade,
              schedule,
              targetMode,
              index,
              point.copyWith(temp: rounded),
            );
          },
        ),
      ),
    );
  }

  void _stepTemperature({
    required DeviceFacade facade,
    required CalendarSnapshot schedule,
    required CalendarMode targetMode,
    required int index,
    required SchedulePoint point,
    required double delta,
  }) {
    final next = (point.temp + delta).clamp(10.0, 40.0);
    final newTemp = double.parse(next.toStringAsFixed(1));
    _patchPoint(
      facade,
      schedule,
      targetMode,
      index,
      point.copyWith(temp: newTemp),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facade = context.read<DeviceFacade>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: AppPalette.transparent,
        elevation: 0,
      ),
      body: BlocListener<DeviceSnapshotCubit, DeviceSnapshot>(
        listenWhen: (prev, next) {
          return prev.schedule.error != next.schedule.error &&
              next.schedule.error != null;
        },
        listener: (context, snap) {
          final msg = snap.schedule.error!;
          SnackBarUtils.showFail(context: context, content: msg);
        },
        child: SafeArea(
          child: BlocBuilder<DeviceSnapshotCubit, DeviceSnapshot>(
            builder: (context, snap) {
              final scheduleSlice = snap.schedule;
              final status = scheduleSlice.status;

              if (status == DeviceSliceStatus.idle ||
                  status == DeviceSliceStatus.loading) {
                return const Loader();
              }

              final schedule = scheduleSlice.data;
              if (status == DeviceSliceStatus.error && schedule == null) {
                return ScheduleEditorErrorRetry(
                  message: scheduleSlice.error ?? 'Failed to load schedule',
                  onRetry: () => facade.schedule.get(force: true),
                );
              }
              if (schedule == null) return const Loader();

              final targetMode = _targetMode(schedule);
              final showDays = targetMode == CalendarMode.weekly;
              final items = schedule
                  .pointsFor(targetMode)
                  .asMap()
                  .entries
                  .where((entry) => _passesFilter(entry.value.daysMask))
                  .toList();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, itemIndex) {
                  final index = items[itemIndex].key;
                  final point = items[itemIndex].value;

                  return Dismissible(
                    key: ValueKey(
                      'sp_${index}_${point.time.hour}_${point.time.minute}'
                      '_${point.temp}_${point.daysMask}',
                    ),
                    direction: DismissDirection.endToStart,
                    background: const SizedBox.shrink(),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppPalette.destructiveBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: AppPalette.destructiveFg,
                      ),
                    ),
                    onDismissed: (_) {
                      unawaited(
                        OshAnalytics.logEvent(
                          OshAnalyticsEvents.schedulePointRemoved,
                          parameters: {'mode': targetMode.id},
                        ),
                      );
                      _removePoint(facade, schedule, targetMode, index);
                    },
                    child: SchedulePointTile(
                      timeText: formatScheduleEditorTime(point.time),
                      valueText:
                          '${formatScheduleEditorTemperature(point.temp)}°C',
                      daysMask: point.daysMask,
                      showDays: showDays,
                      onTapTime: () => unawaited(
                        _openTimeEditor(
                          context: context,
                          facade: facade,
                          schedule: schedule,
                          targetMode: targetMode,
                          index: index,
                          point: point,
                        ),
                      ),
                      onDecTemp: () => _stepTemperature(
                        facade: facade,
                        schedule: schedule,
                        targetMode: targetMode,
                        index: index,
                        point: point,
                        delta: -0.5,
                      ),
                      onIncTemp: () => _stepTemperature(
                        facade: facade,
                        schedule: schedule,
                        targetMode: targetMode,
                        index: index,
                        point: point,
                        delta: 0.5,
                      ),
                      onToggleDay: (dayBit) {
                        if (!showDays) return;
                        final newMask =
                            WeekdayMask.toggle(point.daysMask, dayBit);
                        _patchPoint(
                          facade,
                          schedule,
                          targetMode,
                          index,
                          point.copyWith(daysMask: newMask),
                        );
                      },
                      onTapValue: () => unawaited(
                        _openTemperatureEditor(
                          context: context,
                          facade: facade,
                          schedule: schedule,
                          targetMode: targetMode,
                          index: index,
                          point: point,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 10),
        child: ScheduleAddPointFab(
          onPressed: () {
            unawaited(
              OshAnalytics.logEvent(
                OshAnalyticsEvents.schedulePointAdded,
                parameters: {
                  'mode': widget.mode?.id ?? facade.schedule.current?.mode.id,
                },
              ),
            );
            final schedule =
                context.read<DeviceSnapshotCubit>().state.schedule.data;
            if (schedule == null) return;
            _addPoint(
              facade,
              schedule,
              _targetMode(schedule),
            );
          },
        ),
      ),
      bottomNavigationBar: BlocBuilder<DeviceSnapshotCubit, DeviceSnapshot>(
        builder: (context, snap) {
          final mode =
              widget.mode ?? snap.schedule.data?.mode ?? CalendarMode.off;
          if (mode != CalendarMode.weekly) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            top: false,
            child: ScheduleWeekdayFilterBar(
              mask: _filterMask,
              onToggle: (dayBit) => setState(
                () => _filterMask = WeekdayMask.toggle(_filterMask, dayBit),
              ),
            ),
          );
        },
      ),
    );
  }
}
