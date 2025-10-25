import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_actions_cubit.dart';
import 'package:oshmobile/features/devices/details/presentation/cubit/device_state_cubit.dart';
import 'package:oshmobile/generated/l10n.dart';

/// Bottom-nav-like bar to show and switch thermostat modes with optimistic UI.
/// Modes: off, antifreeze, manual, daily, weekly.
/// - Reads current mode from [bind] via DeviceStateCubit (e.g. 'climate.mode').
/// - Sends [command] via DeviceActionsCubit {'mode': <id>}.
/// - Optimistic selection is highlighted immediately; cleared on confirmation or timeout.
class ThermostatModeBar extends StatefulWidget {
  const ThermostatModeBar({
    super.key,
    required this.deviceId,
    required this.bind,
    this.command = 'climate.set_mode',
    this.visibleModes,
    this.optimisticTimeout = const Duration(seconds: 5),
  });

  final String deviceId;
  final String bind; // e.g. 'climate.mode'
  final String command; // e.g. 'climate.set_mode'
  final List<String>? visibleModes; // optionally restrict visible items
  final Duration optimisticTimeout; // auto-clear optimistic highlight

  @override
  State<ThermostatModeBar> createState() => _ThermostatModeBarState();
}

class _ThermostatModeBarState extends State<ThermostatModeBar> {
  String? _optimistic; // pending desired mode (lowercase)
  Timer? _revertTimer; // timeout reverter

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  void _startOptimistic(String modeId) {
    _revertTimer?.cancel();
    setState(() => _optimistic = modeId);
    _revertTimer = Timer(widget.optimisticTimeout, () {
      if (!mounted) return;
      // If device didn't confirm by timeout, drop optimistic highlight.
      setState(() => _optimistic = null);
    });
  }

  IconData _iconFor(String id) {
    switch (id) {
      case 'off':
        return Icons.power_settings_new;
      case 'antifreeze':
        return Icons.ac_unit;
      case 'manual':
        return Icons.touch_app;
      case 'daily':
        return Icons.schedule;
      case 'weekly':
        return Icons.calendar_today;
      default:
        return Icons.tune;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final localized = <String, String>{
      'off': s.ModeOff,
      'antifreeze': s.ModeAntifreeze,
      'manual': s.ModeManual,
      'daily': s.ModeDaily,
      'weekly': s.ModeWeekly,
    };

    // Actual mode from state (normalized to lowercase)
    final String? current = context.select<DeviceStateCubit, String?>((c) {
      final v = c.state.valueOf(widget.bind);
      return v?.toString().trim().toLowerCase();
    });

    // If device confirmed our optimistic choice — clear the optimistic flag post-frame.
    if (_optimistic != null && current == _optimistic) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _revertTimer?.cancel();
        _revertTimer = null;
        _optimistic = null; // no visible change; safe without setState in post-frame
        // если хочешь анимировать исчезновение pending — используй setState
      });
    }

    final all = const ['off', 'antifreeze', 'manual', 'daily', 'weekly'];
    final modes = widget.visibleModes == null ? all : all.where((m) => widget.visibleModes!.contains(m)).toList();

    // Effective (what UI highlights): prefer optimistic if present.
    String? effective = _optimistic ?? current;

    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            for (final id in modes) ...[
              Expanded(
                child: _ModeItem(
                  id: id,
                  label: localized[id] ?? id,
                  icon: _iconFor(id),
                  selected: effective == id,
                  // "pending" means we picked this id, but device hasn't confirmed yet
                  pending: _optimistic == id && current != id,
                  onTap: () {
                    if (effective == id) return; // nothing to do
                    _startOptimistic(id);
                    // Send command
                    context.read<DeviceActionsCubit>().sendCommand(
                      widget.deviceId,
                      widget.command,
                      args: {'mode': id},
                    );
                  },
                ),
              ),
              if (id != modes.last) const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.pending = false, // still passed but not visually indicated
  });

  final String id;
  final String label;
  final IconData icon;
  final bool selected;
  final bool pending; // kept for future use if needed
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Colors tuned for glassy/dark background
    final Color fg = selected ? Colors.white : Colors.white70;
    final Color bg = selected ? Colors.white.withOpacity(0.14) : Colors.transparent;
    final Color bd = selected ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.08);

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
            // Icon only (no spinner overlay)
            Icon(icon, size: 22, color: fg),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade, // или ellipsis
              textAlign: TextAlign.center,

              // label,
              // textAlign: TextAlign.center,
              // overflow: TextOverflow.ellipsis,
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
