import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart'; // SchedulePoint
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:oshmobile/features/schedule/presentation/pages/range_page.dart';
import 'package:oshmobile/features/schedule/presentation/pages/manual_temperature_page.dart';
import 'package:oshmobile/features/schedule/presentation/pages/schedule_editor_page.dart';
import 'package:oshmobile/generated/l10n.dart';

/// Centralized navigation for thermostat modes (CalendarMode-based).
/// Flow:
///   - openForCurrentMode: route by current CalendarMode from DeviceScheduleCubit
///   - openManual / openRange / openSchedule: explicit variants
class ThermostatModeNavigator {
  /// Dispatch by current CalendarMode from the cubit.
  static Future<void> openForCurrentMode(BuildContext context) async {
    final mode = context.read<DeviceScheduleCubit>().state.mode;

    if (mode == CalendarMode.on) {
      return _openOn(context);
    }
    if (mode == CalendarMode.range) {
      return _openRange(context);
    }
    if (mode == CalendarMode.daily || mode == CalendarMode.weekly) {
      return _openSchedule(context, mode: mode);
    }
    // off → do nothing
  }

  /// Open manual setpoint editor.
  /// On save: updates the MANUAL list to a single 00:00 setpoint for all days and sets mode=manual.
  static Future<void> _openOn(BuildContext context) async {
    final cubit = context.read<DeviceScheduleCubit>();

    // Initial value: prefer current manual list value if present; otherwise fallback
    double initial = 21.0;
    final s = cubit.state;
    if (s is DeviceScheduleReady) {
      final on = s.snap.lists[CalendarMode.on] ?? const <SchedulePoint>[];
      final p = on.isNotEmpty ? on.first : cubit.currentPoint();
      if (p != null) initial = p.temp;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: ManualTemperaturePage(
              initial: initial,
              title: S.of(context).ManualTemperature,
              onSave: (v) {
                final pt = SchedulePoint(
                  time: const TimeOfDay(hour: 0, minute: 0),
                  daysMask: WeekdayMask.all,
                  temp: v,
                );
                cubit.setMode(CalendarMode.on);
                cubit.setListFor(CalendarMode.on, [pt]);
              },
            ),
          ),
        ))
        .then((_) => cubit.saveAll());
  }

  /// Open range editor.
  /// On save: updates the RANGE values and sets mode=range.
  static Future<void> _openRange(BuildContext context) async {
    final cubit = context.read<DeviceScheduleCubit>();

    // Initial range: prefer snapshot range, fallback to defaults.
    double minInit = ScheduleRange.defaultMin;
    double maxInit = ScheduleRange.defaultMax;
    final s = cubit.state;
    if (s is DeviceScheduleReady) {
      minInit = s.range.min;
      maxInit = s.range.max;
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: ScheduleRangePage(
              initialMin: minInit,
              initialMax: maxInit,
              title: S.of(context).ModeRange,
              onSave: (minV, maxV) {
                final lo = (minV <= maxV) ? minV : maxV;
                final hi = (maxV >= minV) ? maxV : minV;
                cubit.setRange(
                  ScheduleRange(
                    min: double.parse(lo.toStringAsFixed(1)),
                    max: double.parse(hi.toStringAsFixed(1)),
                  ),
                );
                cubit.setMode(CalendarMode.range);
              },
            ),
          ),
        ))
        .then((_) => cubit.saveAll());
  }

  /// Open daily/weekly schedule editor for the given mode.
  /// On save: replaces the ACTIVE list (we switch to that mode before opening) and persists.
  static Future<void> _openSchedule(BuildContext context, {required CalendarMode mode}) async {
    final cubit = context.read<DeviceScheduleCubit>();
    final title = (mode.id == CalendarMode.weekly.id) ? S.of(context).ModeWeekly : S.of(context).ModeDaily;

    // Ensure the editor works with the correct active list
    cubit.setMode(mode);

    await Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => BlocProvider.value(value: cubit, child: ScheduleEditorPage(title: title))))
        .then((_) => cubit.saveAll());
  }

  // -------- Explicit public variants (optional API) --------

  static Future<void> openOn(BuildContext context) => _openOn(context);

  static Future<void> openRange(BuildContext context) => _openRange(context);

  static Future<void> openWeekly(BuildContext context) => _openSchedule(context, mode: CalendarMode.weekly);

  static Future<void> openDaily(BuildContext context) => _openSchedule(context, mode: CalendarMode.daily);
}
