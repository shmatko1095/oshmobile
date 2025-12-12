import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/loader.dart';
import 'package:oshmobile/core/utils/show_shackbar.dart';
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
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
          color: Colors.black,
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
                        child: Text(S.of(context).Cancel, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      MaterialButton(
                        onPressed: () => Navigator.pop(ctx, temp),
                        child: Text(S.of(context).Done, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime(2020, 1, 1, initial.hour, initial.minute),
                    use24hFormat: use24h,
                    minuteInterval: minuteInterval,
                    onDateTimeChanged: (dt) => temp = TimeOfDay(hour: dt.hour, minute: dt.minute),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtTemp(double v) => v.toStringAsFixed(1);

  bool _passesFilter(int mask) => _filterMask == 0 ? true : (mask & _filterMask) != 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<DeviceScheduleCubit, DeviceScheduleState>(
        listenWhen: (_, s) => s is DeviceScheduleReady && s.flash != null,
        listener: (context, s) {
          final msg = (s as DeviceScheduleReady).flash!;
          SnackBarUtils.showFail(context: context, content: msg);
        },
        child: SafeArea(
          child: BlocBuilder<DeviceScheduleCubit, DeviceScheduleState>(
            builder: (context, state) {
              switch (state) {
                case DeviceScheduleLoading():
                  return const Loader();
                case DeviceScheduleError(:final message):
                  return _ErrorRetry(
                    message: message,
                    onRetry: () => context.read<DeviceScheduleCubit>().rebind(),
                  );
                case DeviceScheduleReady():
                  final showDays = state.mode.id == CalendarMode.weekly.id;
                  final items = state.points.asMap().entries.where((e) => _passesFilter(e.value.daysMask)).toList();

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final idx = items[i].key;
                      final p = items[i].value;

                      return Dismissible(
                        key: ValueKey('sp_${idx}_${p.time.hour}_${p.time.minute}_${p.min}_${p.max}_${p.daysMask}'),
                        direction: DismissDirection.endToStart,
                        background: const SizedBox.shrink(),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                        onDismissed: (_) => context.read<DeviceScheduleCubit>().removeAt(idx),
                        child: _ScheduleTile(
                          timeText: _fmtTime(p.time),
                          valueText:
                              p.min == p.max ? '${_fmtTemp(p.min)}°C' : '${_fmtTemp(p.min)}–${_fmtTemp(p.max)}°C',
                          daysMask: p.daysMask,
                          showDays: showDays,

                          // time picker
                          onTapTime: () async {
                            final picked = await _showWheelTimePicker(context, initial: p.time, minuteInterval: 1);
                            if (picked != null) {
                              context.read<DeviceScheduleCubit>().changePoint(idx, p.copyWith(time: picked));
                            }
                          },

                          // fine range edits (still available on the right)
                          onDecMin: () {
                            final next = (p.min - 0.5).clamp(5.0, 35.0);
                            final newMin = double.parse(next.toStringAsFixed(1));
                            final newMax = (p.min == p.max) ? newMin : p.max.clamp(newMin, 35.0);
                            context.read<DeviceScheduleCubit>().changePoint(idx, p.copyWith(min: newMin, max: newMax));
                          },
                          onIncMax: () {
                            final base = p.max + 0.5;
                            final next = base.clamp(5.0, 35.0);
                            final newMax = double.parse(next.toStringAsFixed(1));
                            final newMin = (p.min == p.max) ? newMax : p.min.clamp(5.0, newMax);
                            context.read<DeviceScheduleCubit>().changePoint(idx, p.copyWith(min: newMin, max: newMax));
                          },

                          onToggleDay: (d) {
                            if (!showDays) return;
                            final newMask = WeekdayMask.toggle(p.daysMask, d);
                            context.read<DeviceScheduleCubit>().changePoint(idx, p.copyWith(daysMask: newMask));
                          },

                          onTapValue: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => ManualTemperaturePage(
                                  title: S.of(context).SetTemperature,
                                  initial: p.max,
                                  onSave: (v) {
                                    final vv = double.parse(v.toStringAsFixed(1));
                                    context.read<DeviceScheduleCubit>().changePoint(idx, p.copyWith(min: vv, max: vv));
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
              }
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 10),
        child: _AddPointFab(onPressed: () => context.read<DeviceScheduleCubit>().addPoint()),
      ),
      bottomNavigationBar: BlocBuilder<DeviceScheduleCubit, DeviceScheduleState>(
        builder: (context, state) {
          final showDays = CalendarMode.weekly == context.read<DeviceScheduleCubit>().getMode();
          if (showDays) {
            return SafeArea(
              top: false,
              child: _WeekdayFilterBar(
                mask: _filterMask,
                onToggle: (d) => setState(() => _filterMask = WeekdayMask.toggle(_filterMask, d)),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
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
    final bg = Colors.white.withValues(alpha: 0.06);
    final border = Colors.white.withValues(alpha: 0.12);
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: bg,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
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
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, style: const TextStyle(color: Colors.white70)),
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
    required this.onDecMin,
    required this.onIncMax,
    required this.onToggleDay,
    required this.onTapValue,
  });

  final String timeText;
  final String valueText;
  final int daysMask;
  final bool showDays;

  final VoidCallback onTapTime;
  final VoidCallback onDecMin;
  final VoidCallback onIncMax;
  final void Function(int dayBit) onToggleDay;
  final VoidCallback onTapValue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (ctx, constraints) {
                final Widget time = InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTapTime,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
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
                    onDecMin: onDecMin,
                    onIncMax: onIncMax,
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
      ),
    );
  }
}

class _TempRangeStepper extends StatelessWidget {
  const _TempRangeStepper({
    required this.valueText,
    required this.onDecMin,
    required this.onIncMax,
    required this.onTapValue,
  });

  final String valueText;
  final VoidCallback onDecMin;
  final VoidCallback onIncMax;
  final VoidCallback onTapValue;

  static const _coolBlue = Color(0xFF40C4FF); // LightBlue A200
  static const _warmRed = Color(0xFFFF5252); // Red A200

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
        _IconBtn(icon: Icons.keyboard_arrow_down, onTap: onDecMin, color: _coolBlue),
        const SizedBox(width: 4),
        _IconBtn(icon: Icons.keyboard_arrow_up, onTap: onIncMax, color: _warmRed),
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
    final bg = selected ? Colors.white.withValues(alpha: 0.16) : null;
    final bd = selected ? Colors.white.withValues(alpha: 0.26) : Colors.white.withValues(alpha: 0);
    final fg = selected ? Colors.white : Colors.white70;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 6 : 8),
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
