import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/schedule/presentation/pages/manual_temperature_page.dart';
import 'package:oshmobile/features/schedule/presentation/utils.dart';
import 'package:oshmobile/generated/l10n.dart';

import '../../domain/models/schedule_models.dart';

class ScheduleEditorPage extends StatefulWidget {
  const ScheduleEditorPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<ScheduleEditorPage> createState() => _ScheduleEditorPageState();
}

class _ScheduleEditorPageState extends State<ScheduleEditorPage> {
  int _filterMask = 0;

  Future<TimeOfDay?> _showWheelTimePicker(
    BuildContext context, {
    required TimeOfDay initial,
    int minuteInterval = 1,
  }) {
    return showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (ctx) {
        TimeOfDay temp = initial;
        final use24h = MediaQuery.of(ctx).alwaysUse24HourFormat;

        return Container(
          height: 300,
          color: AppPalette.canvas,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MaterialButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(S.of(context).Cancel,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      MaterialButton(
                        onPressed: () => Navigator.pop(ctx, temp),
                        child: Text(S.of(context).Done,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime:
                        DateTime(2020, 1, 1, initial.hour, initial.minute),
                    use24hFormat: use24h,
                    minuteInterval: minuteInterval,
                    onDateTimeChanged: (dt) =>
                        temp = TimeOfDay(hour: dt.hour, minute: dt.minute),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtTemp(double v) => v.toStringAsFixed(1);

  bool _passesFilter(int mask) =>
      _filterMask == 0 ? true : (mask & _filterMask) != 0;

  @override
  Widget build(BuildContext context) {
    final facade = context.read<DeviceFacade>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
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
                return _ErrorRetry(
                  message: scheduleSlice.error ?? 'Failed to load schedule',
                  onRetry: () => facade.schedule.get(force: true),
                );
              }
              if (schedule == null) return const Loader();

              final showDays = schedule.mode.id == CalendarMode.weekly.id;
              final items = schedule
                  .pointsFor(schedule.mode)
                  .asMap()
                  .entries
                  .where((e) => _passesFilter(e.value.daysMask))
                  .toList();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final idx = items[i].key;
                  final p = items[i].value;

                  return Dismissible(
                    key: ValueKey(
                        'sp_${idx}_${p.time.hour}_${p.time.minute}_${p.temp}_${p.daysMask}'),
                    direction: DismissDirection.endToStart,
                    background: const SizedBox.shrink(),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppPalette.destructiveBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete,
                          color: AppPalette.destructiveFg),
                    ),
                    onDismissed: (_) => facade.schedule.removePoint(idx),
                    child: _ScheduleTile(
                      timeText: _fmtTime(p.time),
                      valueText: '${_fmtTemp(p.temp)}°C',
                      daysMask: p.daysMask,
                      showDays: showDays,
                      onTapTime: () async {
                        final picked = await _showWheelTimePicker(
                          context,
                          initial: p.time,
                          minuteInterval: 1,
                        );
                        if (!mounted || picked == null) return;
                        facade.schedule
                            .patchPoint(idx, p.copyWith(time: picked));
                      },
                      onDecTemp: () {
                        final next = (p.temp - 0.5).clamp(5.0, 35.0);
                        final newTemp = double.parse(next.toStringAsFixed(1));
                        facade.schedule
                            .patchPoint(idx, p.copyWith(temp: newTemp));
                      },
                      onIncTemp: () {
                        final next = (p.temp + 0.5).clamp(5.0, 35.0);
                        final newTemp = double.parse(next.toStringAsFixed(1));
                        facade.schedule
                            .patchPoint(idx, p.copyWith(temp: newTemp));
                      },
                      onToggleDay: (d) {
                        if (!showDays) return;
                        final newMask = WeekdayMask.toggle(p.daysMask, d);
                        facade.schedule.patchPoint(
                          idx,
                          p.copyWith(daysMask: newMask),
                        );
                      },
                      onTapValue: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => ManualTemperaturePage(
                              title: S.of(context).SetTemperature,
                              initial: p.temp,
                              onSave: (v) {
                                final vv = double.parse(v.toStringAsFixed(1));
                                facade.schedule.patchPoint(
                                  idx,
                                  p.copyWith(temp: vv),
                                );
                              },
                            ),
                          ),
                        );
                      },
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
        child: _AddPointFab(onPressed: () => facade.schedule.addPoint()),
      ),
      bottomNavigationBar: BlocBuilder<DeviceSnapshotCubit, DeviceSnapshot>(
        builder: (context, snap) {
          final mode = snap.schedule.data?.mode ?? CalendarMode.off;
          if (mode != CalendarMode.weekly) {
            return const SizedBox.shrink();
          }

          return SafeArea(
            top: false,
            child: _WeekdayFilterBar(
              mask: _filterMask,
              onToggle: (d) => setState(
                  () => _filterMask = WeekdayMask.toggle(_filterMask, d)),
            ),
          );
        },
      ),
    );
  }
}

class _AddPointFab extends StatelessWidget {
  const _AddPointFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bg = AppPalette.surfaceRaised;
    final shadow = Colors.black.withValues(alpha: 0.25);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
        borderRadius: BorderRadius.circular(AppPalette.radiusLg),
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: bg,
        foregroundColor: AppPalette.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppPalette.radiusLg),
        ),
        child: const Icon(Icons.add_rounded, size: 26),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: Text(S.of(context).Retry)),
      ]),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.timeText,
    required this.valueText,
    required this.daysMask,
    required this.showDays,
    required this.onTapTime,
    required this.onDecTemp,
    required this.onIncTemp,
    required this.onToggleDay,
    required this.onTapValue,
  });

  final String timeText;
  final String valueText;
  final int daysMask;
  final bool showDays;

  final VoidCallback onTapTime;
  final VoidCallback onDecTemp;
  final VoidCallback onIncTemp;
  final void Function(int dayBit) onToggleDay;
  final VoidCallback onTapValue;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (ctx, constraints) {
              final Widget time = InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTapTime,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  child: Text(
                    timeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );

              final Widget stepper = FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: _TempRangeStepper(
                  valueText: valueText,
                  onDecTemp: onDecTemp,
                  onIncTemp: onIncTemp,
                  onTapValue: onTapValue,
                ),
              );

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: time),
                  const SizedBox(width: 12),
                  Flexible(fit: FlexFit.loose, child: stepper),
                ],
              );
            },
          ),
          if (showDays) const SizedBox(height: 10),
          if (showDays)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 4,
                runSpacing: 6,
                children: [
                  for (final d in WeekdayMask.order)
                    _DayChip(
                      label: shortLabel(context, d),
                      selected: WeekdayMask.has(daysMask, d),
                      onTap: () => onToggleDay(d),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TempRangeStepper extends StatelessWidget {
  const _TempRangeStepper({
    required this.valueText,
    required this.onDecTemp,
    required this.onIncTemp,
    required this.onTapValue,
  });

  final String valueText;
  final VoidCallback onDecTemp;
  final VoidCallback onIncTemp;
  final VoidCallback onTapValue;

  static const _coolBlue = AppPalette.accentPrimary;
  static const _warmRed = AppPalette.accentWarning;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // tap on value -> open temperature picker page
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTapValue,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              valueText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28, // same as time
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _IconBtn(
            icon: Icons.keyboard_arrow_down,
            onTap: onDecTemp,
            color: _coolBlue),
        const SizedBox(width: 4),
        _IconBtn(
            icon: Icons.keyboard_arrow_up, onTap: onIncTemp, color: _warmRed),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 28,
          color: color ?? Colors.white, // colored arrows; defaults to white
        ),
      ),
    );
  }
}

class _WeekdayFilterBar extends StatelessWidget {
  const _WeekdayFilterBar({required this.mask, required this.onToggle});

  final int mask;
  final void Function(int dayBit) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final d in WeekdayMask.order)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _DayChip(
                  label: shortLabel(context, d),
                  selected: WeekdayMask.has(mask, d),
                  onTap: () => onToggle(d),
                  dense: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppPalette.accentPrimary.withValues(alpha: 0.24)
        : Colors.transparent;
    final bd = selected
        ? AppPalette.accentPrimary.withValues(alpha: 0.42)
        : Colors.transparent;
    final fg = selected ? Colors.white : AppPalette.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.symmetric(
            horizontal: dense ? 8 : 10, vertical: dense ? 6 : 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bd),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w700,
            fontSize: dense ? 12 : 13,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
