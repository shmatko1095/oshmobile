import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/utils.dart';

/// Bottom-nav-like bar to show and switch thermostat modes with optimistic UI.
/// Modes: off, range, manual, daily, weekly.
/// - Reads current mode from facade snapshot.
/// - Optimistic selection is highlighted immediately; cleared on confirmation or timeout.
class ThermostatModeBar extends StatefulWidget {
  const ThermostatModeBar({
    super.key,
    this.visibleModes,
    this.writable = true,
    this.optimisticTimeout = const Duration(seconds: 5),
  });

  final List<CalendarMode>? visibleModes;
  final bool writable;
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
    final current = context.select<DeviceSnapshotCubit, CalendarMode>((c) {
      final raw = c.state.controlState.data?['schedule_mode']?.toString();
      return CalendarMode.all.firstWhereOrNull((mode) => mode.id == raw) ??
          c.state.schedule.data?.mode ??
          CalendarMode.off;
    });

    // If device confirmed our optimistic choice — clear the optimistic flag post-frame.
    if (_optimistic != null && current == _optimistic) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _revertTimer?.cancel();
        _revertTimer = null;
        _optimistic =
            null; // no visible change; safe without setState in post-frame
      });
    }

    final modes = widget.visibleModes == null
        ? CalendarMode.all
        : CalendarMode.all
            .where((m) => widget.visibleModes!.contains(m))
            .toList();

    // Effective (what UI highlights): prefer optimistic if present.
    CalendarMode? effective = _optimistic ?? current;

    return AppGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          for (final mode in modes) ...[
            Expanded(
              child: _ModeItem(
                mode: mode,
                selected: effective == mode,
                pending: _optimistic == mode && current != mode,
                onTap: !widget.writable
                    ? null
                    : () {
                        if (effective == mode) return;
                        _startOptimistic(mode);
                        unawaited(context
                            .read<DeviceFacade>()
                            .schedule
                            .commandSetMode(mode));
                      },
              ),
            ),
            if (mode != modes.last) const SizedBox(width: 6),
          ],
        ],
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
  final VoidCallback? onTap;

  IconData _iconFor(final CalendarMode mode) {
    switch (mode) {
      case CalendarMode.off:
        return Icons.power_settings_new;
      case CalendarMode.range:
        return Icons.unfold_more;
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
    final Color fg = selected ? Colors.white : AppPalette.textSecondary;
    final Color bg = selected
        ? AppPalette.accentPrimary.withValues(alpha: 0.22)
        : Colors.transparent;
    final Color bd = selected
        ? AppPalette.accentPrimary.withValues(alpha: 0.4)
        : Colors.transparent;

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
              duration: AppPalette.motionBase,
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
