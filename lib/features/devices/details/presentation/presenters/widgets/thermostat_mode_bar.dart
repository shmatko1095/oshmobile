import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/common/widgets/app_card.dart';
import 'package:oshmobile/core/theme/app_palette.dart';
import 'package:oshmobile/features/devices/details/presentation/presenters/widgets/tiles/glass_stat_card.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/presentation/open_mode_editor.dart';
import 'package:oshmobile/features/schedule/presentation/utils.dart';
import 'package:oshmobile/generated/l10n.dart';
import 'package:oshmobile/init_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';

const thermostatModeBarCalendarHintSeenPrefsKey =
    'thermostat_mode_bar_calendar_hint_seen_v1';

/// Bottom-nav-like bar to show and switch thermostat modes with optimistic UI.
/// Modes: off, range, manual, daily, weekly.
/// - Reads current mode from facade snapshot.
/// - Optimistic selection is highlighted immediately; cleared on confirmation or timeout.
class ThermostatModeBar extends StatefulWidget {
  const ThermostatModeBar({
    super.key,
    required this.modeBind,
    this.visibleModes,
    this.writable = true,
    this.optimisticTimeout = const Duration(seconds: 5),
  });

  final String modeBind;
  final List<CalendarMode>? visibleModes;
  final bool writable;
  final Duration optimisticTimeout;

  @override
  State<ThermostatModeBar> createState() => _ThermostatModeBarState();
}

class _ThermostatModeBarState extends State<ThermostatModeBar> {
  CalendarMode? _optimistic;
  Timer? _revertTimer;
  SharedPreferences? _prefs;
  bool _hintSeen = true;
  bool _editorOpening = false;

  @override
  void initState() {
    super.initState();
    if (locator.isRegistered<SharedPreferences>()) {
      _prefs = locator<SharedPreferences>();
      _hintSeen =
          _prefs!.getBool(thermostatModeBarCalendarHintSeenPrefsKey) ?? false;
    }
  }

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  bool _isEditableMode(CalendarMode mode) => mode != CalendarMode.off;

  void _startOptimistic(CalendarMode modeId) {
    _revertTimer?.cancel();
    setState(() => _optimistic = modeId);
    _revertTimer = Timer(widget.optimisticTimeout, () {
      if (!mounted) return;
      // If device didn't confirm by timeout, drop optimistic highlight.
      setState(() => _optimistic = null);
    });
  }

  void _trackModeSelection(CalendarMode current, CalendarMode next) {
    if (current == next) return;
    unawaited(
      OshAnalytics.logEvent(
        OshAnalyticsEvents.scheduleModeSelected,
        parameters: {
          'from_mode': current.id,
          'to_mode': next.id,
          'source': 'mode_bar',
        },
      ),
    );
  }

  void _switchMode(CalendarMode current, CalendarMode next) {
    if (_editorOpening || current == next) return;
    _trackModeSelection(current, next);
    _startOptimistic(next);
    unawaited(
      context.read<DeviceFacade>().schedule.commandSetMode(
            next,
            source: 'mode_bar',
          ),
    );
  }

  Future<void> _openModeEditor(
    CalendarMode mode, {
    required String source,
  }) async {
    if (_editorOpening || !_isEditableMode(mode) || !widget.writable) return;

    if (!_hintSeen) {
      _hintSeen = true;
      _prefs?.setBool(thermostatModeBarCalendarHintSeenPrefsKey, true);
    }

    setState(() => _editorOpening = true);
    try {
      await ThermostatModeNavigator.openForMode(
        context,
        mode,
        source: source,
      );
    } finally {
      if (mounted) {
        setState(() => _editorOpening = false);
      }
    }
  }

  String? _semanticsHint(
    BuildContext context,
    CalendarMode mode, {
    required bool selected,
  }) {
    final s = S.of(context);
    if (!_isEditableMode(mode)) {
      return selected ? null : s.ThermostatModeBarSemanticsOff;
    }
    return selected
        ? s.ThermostatModeBarSemanticsActiveEditable
        : s.ThermostatModeBarSemanticsInactiveEditable;
  }

  @override
  Widget build(BuildContext context) {
    final current = context.select<DeviceSnapshotCubit, CalendarMode>((c) {
      final raw = readBind(
        c.state.controlState.data ?? const <String, dynamic>{},
        widget.modeBind,
      )?.toString();
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
    final effective = _optimistic ?? current;
    final showHint =
        widget.writable && !_hintSeen && modes.any(_isEditableMode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          backgroundColor: statSurfaceColor(context),
          borderColor: statBorderColor(context),
          child: Row(
            children: [
              for (final mode in modes) ...[
                Expanded(
                  child: _ModeItem(
                    mode: mode,
                    selected: effective == mode,
                    semanticsHint: _semanticsHint(
                      context,
                      mode,
                      selected: effective == mode,
                    ),
                    onTap: !widget.writable
                        ? null
                        : () {
                            if (_editorOpening) return;
                            if (!_isEditableMode(mode)) {
                              if (effective == mode) return;
                              _switchMode(current, mode);
                              return;
                            }
                            if (effective == mode) {
                              unawaited(
                                _openModeEditor(
                                  mode,
                                  source: 'mode_bar_active_tap',
                                ),
                              );
                              return;
                            }
                            _switchMode(current, mode);
                          },
                    onLongPress: !widget.writable || !_isEditableMode(mode)
                        ? null
                        : () {
                            if (_editorOpening) return;
                            unawaited(
                              _openModeEditor(
                                mode,
                                source: 'mode_bar_long_press',
                              ),
                            );
                          },
                  ),
                ),
                if (mode != modes.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: AppPalette.motionFast,
          child: !showHint
              ? const SizedBox.shrink()
              : Padding(
                  key: const ValueKey('mode-bar-hint'),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Text(
                    S.of(context).ThermostatModeBarHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statMutedColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.mode,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.semanticsHint,
  });

  final CalendarMode mode;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticsHint;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = labelForCalendarMode(context, mode);
    final Color fg = selected
        ? (isDark ? AppPalette.white : AppPalette.lightTextPrimary)
        : (isDark ? AppPalette.textSecondary : AppPalette.lightTextSecondary);
    final Color bg = selected
        ? AppPalette.accentPrimary.withValues(alpha: isDark ? 0.22 : 0.14)
        : AppPalette.transparent;
    final Color bd = selected
        ? AppPalette.accentPrimary.withValues(alpha: isDark ? 0.4 : 0.32)
        : AppPalette.transparent;

    return Semantics(
      container: true,
      button: onTap != null || onLongPress != null,
      enabled: onTap != null || onLongPress != null,
      selected: selected,
      label: label,
      hint: semanticsHint,
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          onLongPress: onLongPress,
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
                  label,
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
        ),
      ),
    );
  }
}
