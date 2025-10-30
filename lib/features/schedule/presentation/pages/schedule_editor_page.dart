import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

import '../../domain/models/schedule_models.dart';
import '../cubit/schedule_cubit.dart';

class ScheduleEditorPage extends StatefulWidget {
  const ScheduleEditorPage({super.key, required this.deviceId, required this.title});

  final String deviceId;
  final String title;

  @override
  State<ScheduleEditorPage> createState() => _ScheduleEditorPageState();
}

class _ScheduleEditorPageState extends State<ScheduleEditorPage> {
  int _filterMask = 0;

  CalendarMode _modeFromDevice(dynamic v) {
    final s = v?.toString().toLowerCase() ?? '';
    if (s == 'daily') return CalendarMode.daily;
    if (s == 'weekly') return CalendarMode.weekly;
    return CalendarMode.weekly; // default
  }

  Future<TimeOfDay?> _showWheelTimePicker(BuildContext context, {required TimeOfDay initial, int minuteInterval = 5}) {
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
                        child: Text(
                          S.of(context).Cancel,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      MaterialButton(
                        onPressed: () => Navigator.pop(ctx, temp),
                        child: Text(
                          S.of(context).Done,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
                    onDateTimeChanged: (dt) {
                      temp = TimeOfDay(hour: dt.hour, minute: dt.minute);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final devMode = context.read<DeviceStateCubit>().state.get(Signal('climate.mode'));
    context.read<ScheduleCubit>().load(_modeFromDevice(devMode));
  }

  String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtTemp(double v) => v.toStringAsFixed(1);

  bool _passesFilter(int mask) => _filterMask == 0 ? true : (mask & _filterMask) != 0;

  void _onAddPoint(CalendarMode mode) {
    final now = TimeOfDay.now();
    final roundMin = ((now.minute + 14) ~/ 15) * 15;
    final t = TimeOfDay(hour: (now.hour + (roundMin ~/ 60)) % 24, minute: roundMin % 60);
    context.read<ScheduleCubit>().addPoint(
          SchedulePoint(
            time: t,
            temperature: 21.0,
            daysMask: mode == CalendarMode.weekly
                ? WeekdayMask.mon | WeekdayMask.tue | WeekdayMask.wed | WeekdayMask.thu | WeekdayMask.fri
                : 0,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<ScheduleCubit, ScheduleState>(
        listenWhen: (_, s) => s is ScheduleReady && s.flash != null,
        listener: (context, s) {
          final msg = (s as ScheduleReady).flash!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        },
        child: SafeArea(
          child: BlocBuilder<ScheduleCubit, ScheduleState>(
            builder: (context, state) {
              if (state is ScheduleLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ScheduleError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.read<ScheduleCubit>().load(state.mode),
                        child: Text(S.of(context).Retry),
                      ),
                    ],
                  ),
                );
              }

              final s = state as ScheduleReady;
              final showDays = s.mode == CalendarMode.weekly;
              final items = s.points.asMap().entries.where((e) => _passesFilter(e.value.daysMask)).toList();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final idx = items[i].key;
                  final p = items[i].value;
                  return Dismissible(
                    key: ValueKey('sp_${idx}_${p.time.hour}_${p.time.minute}_${p.temperature}_${p.daysMask}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.redAccent),
                    ),
                    onDismissed: (_) {
                      context.read<ScheduleCubit>().removeAt(idx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(S.of(context).Deleted),
                          action: SnackBarAction(
                            label: S.of(context).Undo,
                            onPressed: () => context.read<ScheduleCubit>().addPoint(p),
                          ),
                        ),
                      );
                    },
                    child: _ScheduleTile(
                      timeText: _fmtTime(p.time),
                      tempText: '${_fmtTemp(p.temperature)}°C',
                      daysMask: p.daysMask,
                      showDays: showDays,
                      onTapTime: () async {
                        final picked = await _showWheelTimePicker(context, initial: p.time, minuteInterval: 1);
                        if (picked != null) context.read<ScheduleCubit>().changeTime(idx, picked);
                      },
                      onDecTemp: () {
                        final next = (p.temperature - 0.5).clamp(5.0, 35.0);
                        context.read<ScheduleCubit>().changeTemp(idx, double.parse(next.toStringAsFixed(1)));
                      },
                      onIncTemp: () {
                        final next = (p.temperature + 0.5).clamp(5.0, 35.0);
                        context.read<ScheduleCubit>().changeTemp(idx, double.parse(next.toStringAsFixed(1)));
                      },
                      onToggleDay: (d) => context.read<ScheduleCubit>().toggleDay(idx, d),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<ScheduleCubit, ScheduleState>(
        buildWhen: (p, n) => (p is ScheduleReady ? p.mode : null) != (n is ScheduleReady ? n.mode : null),
        builder: (context, state) {
          final mode = (state is ScheduleReady) ? state.mode : CalendarMode.weekly;
          return FloatingActionButton(
            onPressed: () => _onAddPoint(mode),
            child: const Icon(Icons.add),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<ScheduleCubit, ScheduleState>(
        builder: (context, state) {
          final showDays = state is ScheduleReady && state.mode == CalendarMode.weekly;
          if (!showDays) return const SizedBox.shrink();
          return SafeArea(
            top: false,
            child: _WeekdayFilterBar(
              mask: _filterMask,
              onToggle: (d) => setState(() => _filterMask = WeekdayMask.toggle(_filterMask, d)),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.timeText,
    required this.tempText,
    required this.daysMask,
    required this.showDays,
    required this.onTapTime,
    required this.onDecTemp,
    required this.onIncTemp,
    required this.onToggleDay,
  });

  final String timeText;
  final String tempText;
  final int daysMask;
  final bool showDays;

  final VoidCallback onTapTime;
  final VoidCallback onDecTemp;
  final VoidCallback onIncTemp;
  final void Function(int dayBit) onToggleDay;

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
            Row(
              children: [
                Expanded(
                  child: InkWell(
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
                  ),
                ),
                const SizedBox(width: 12),
                _TempStepper(valueText: tempText, onDec: onDecTemp, onInc: onIncTemp),
              ],
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
                        label: WeekdayMask.shortLabel(d),
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

class _TempStepper extends StatelessWidget {
  const _TempStepper({required this.valueText, required this.onDec, required this.onInc});

  final String valueText;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    final pill = BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    );

    return Container(
      decoration: pill,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBtn(icon: Icons.remove, onTap: onDec),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Text(
              valueText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          _IconBtn(icon: Icons.add, onTap: onInc),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        // decoration: BoxDecoration(
        //   color: Colors.white.withValues(alpha: 0.10),
        //   shape: BoxShape.circle,
        //   border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        // ),
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.white),
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
                  label: WeekdayMask.shortLabel(d),
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
    final bg = selected ? Colors.white.withValues(alpha: 0.16) : null; //Colors.white.withValues(alpha: 0.06);
    final bd = selected ? Colors.white.withValues(alpha: 0.26) : Colors.white.withValues(alpha: 0); //0.10
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
