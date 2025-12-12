import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/network/mqtt/signal_command.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:oshmobile/features/schedule/presentation/utils.dart';

/// Bottom-nav-like bar to show and switch thermostat modes with optimistic UI.
/// Modes: off, antifreeze, manual, daily, weekly.
/// - Reads current mode from [bind] via DeviceStateCubit (e.g. 'climate.mode').
/// - Sends [command] via DeviceActionsCubit {'mode': id}.
/// - Optimistic selection is highlighted immediately; cleared on confirmation or timeout.
class ThermostatModeBar extends StatefulWidget {
  const ThermostatModeBar({
    super.key,
    required this.bind,
    this.visibleModes,
    this.optimisticTimeout = const Duration(seconds: 5),
  });

  final Signal bind;
  final List<CalendarMode>? visibleModes;
  final Duration optimisticTimeout;

  @override
  State<ThermostatModeBar> createState() => _ThermostatModeBarState();
}

class _ThermostatModeBarState extends State<ThermostatModeBar> {
  CalendarMode? _optimistic;
  Timer? _revertTimer;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  void _startOptimistic(CalendarMode modeId) {
    _revertTimer?.cancel();
    setState(() => _optimistic = modeId);
    _revertTimer = Timer(widget.optimisticTimeout, () {
      if (!mounted) return;
      // If device didn't confirm by timeout, drop optimistic highlight.
      setState(() => _optimistic = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = context.select<DeviceScheduleCubit, CalendarMode>((c) => c.getMode());

    // If device confirmed our optimistic choice — clear the optimistic flag post-frame.
    if (_optimistic != null && current == _optimistic) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _revertTimer?.cancel();
        _revertTimer = null;
        _optimistic = null; // no visible change; safe without setState in post-frame
      });
    }

    final modes = widget.visibleModes == null
        ? CalendarMode.all
        : CalendarMode.all.where((m) => widget.visibleModes!.contains(m)).toList();

    // Effective (what UI highlights): prefer optimistic if present.
    CalendarMode? effective = _optimistic ?? current;

    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            for (final mode in modes) ...[
              Expanded(
                child: _ModeItem(
                  mode: mode,
                  selected: effective == mode,
                  pending: _optimistic == mode && current != mode,
                  onTap: () {
                    if (effective == mode) return;
                    _startOptimistic(mode);
                    context.read<DeviceScheduleCubit>().setMode(mode);
                  },
                ),
              ),
              if (mode != modes.last) const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.mode,
    required this.selected,
    required this.onTap,
    this.pending = false, // still passed but not visually indicated
  });

  final CalendarMode mode;
  final bool selected;
  final bool pending; // kept for future use if needed
  final VoidCallback onTap;

  IconData _iconFor(final CalendarMode mode) {
    switch (mode) {
      case CalendarMode.off:
        return Icons.power_settings_new;
      case CalendarMode.antifreeze:
        return Icons.ac_unit;
      case CalendarMode.on:
        return Icons.touch_app;
      case CalendarMode.daily:
        return Icons.schedule;
      case CalendarMode.weekly:
        return Icons.calendar_today;
      default:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors tuned for glassy/dark background
    final Color fg = selected ? Colors.white : Colors.white70;
    final Color bg = selected ? Colors.white.withValues(alpha: 0.14) : Colors.transparent;
    final Color bd = selected ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(mode), size: 22, color: fg),
            const SizedBox(height: 6),
            Text(
              labelForCalendarMode(context, mode),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Active underline indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              height: 2,
              width: selected ? 22 : 0,
              decoration: BoxDecoration(
                color: fg,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
