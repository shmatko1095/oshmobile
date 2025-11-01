import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart'; // SchedulePoint
import 'package:oshmobile/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:oshmobile/features/schedule/presentation/pages/antifreeze_range_page.dart';
import 'package:oshmobile/features/schedule/presentation/pages/manual_temperature_page.dart';
import 'package:oshmobile/features/schedule/presentation/pages/schedule_editor_page.dart';
import 'package:oshmobile/generated/l10n.dart';

/// Centralized navigation for thermostat modes (CalendarMode-based).
/// Flow:
///   - openForCurrentMode: route by current CalendarMode from DeviceScheduleCubit
///   - openManual / openAntifreeze / openSchedule: explicit variants
class ThermostatModeNavigator {
  /// Dispatch by current CalendarMode from the cubit.
  static Future<void> openForCurrentMode(BuildContext context) async {
    final mode = context.read<DeviceScheduleCubit>().getMode();

    if (mode == CalendarMode.manual) {
      return _openManual(context);
    }
    if (mode == CalendarMode.antifreeze) {
      return _openAntifreeze(context);
    }
    if (mode == CalendarMode.daily || mode == CalendarMode.weekly) {
      return _openSchedule(context, mode: mode);
    }
    // off → do nothing
  }

  /// Open manual setpoint editor.
  /// On save: updates the MANUAL list to a single 00:00 setpoint for all days and sets mode=manual.
  static Future<void> _openManual(BuildContext context) async {
    final cubit = context.read<DeviceScheduleCubit>();

    // Initial value: prefer current manual list value if present; otherwise fallback
    double initial = 21.0;
    final s = cubit.state;
    if (s is DeviceScheduleReady) {
      final manual = s.snap.lists[CalendarMode.manual] ?? const <SchedulePoint>[];
      final p = manual.isNotEmpty ? manual.first : cubit.currentPoint();
      if (p != null && p.min == p.max) initial = p.min;
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
                  min: v,
                  max: v,
                );
                cubit.setMode(CalendarMode.manual);
                cubit.setListFor(CalendarMode.manual, [pt]);
              },
            ),
          ),
        ))
        .then((_) => cubit.persistAll());
  }

  /// Open antifreeze range editor.
  /// On save: updates the ANTIFREEZE list to a single 00:00 range for all days and sets mode=antifreeze.
  static Future<void> _openAntifreeze(BuildContext context) async {
    final cubit = context.read<DeviceScheduleCubit>();

    // Initial range: try from antifreeze list; fallback to 5..10°C
    double minInit = 5.0, maxInit = 10.0;
    final s = cubit.state;
    if (s is DeviceScheduleReady) {
      final anti = s.snap.lists[CalendarMode.antifreeze] ?? const <SchedulePoint>[];
      final p = anti.isNotEmpty ? anti.first : cubit.currentPoint();
      if (p != null) {
        minInit = p.min;
        maxInit = p.isRange ? p.max : (p.min + 5.0).clamp(p.min, 35.0);
      }
    }

    await Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: AntifreezeRangePage(
              initialMin: minInit,
              initialMax: maxInit,
              title: S.of(context).ModeAntifreeze,
              onSave: (minV, maxV) {
                final lo = (minV <= maxV) ? minV : maxV;
                final hi = (maxV >= minV) ? maxV : minV;
                final pt = SchedulePoint(
                  time: const TimeOfDay(hour: 0, minute: 0),
                  daysMask: WeekdayMask.all,
                  min: double.parse(lo.toStringAsFixed(1)),
                  max: double.parse(hi.toStringAsFixed(1)),
                );
                cubit.setMode(CalendarMode.antifreeze);
                cubit.setListFor(CalendarMode.antifreeze, [pt]);
              },
            ),
          ),
        ))
        .then((_) => cubit.persistAll());
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
        .then((_) => cubit.persistAll());
  }

  // -------- Explicit public variants (optional API) --------

  static Future<void> openManual(BuildContext context) => _openManual(context);

  static Future<void> openAntifreeze(BuildContext context) => _openAntifreeze(context);

  static Future<void> openWeekly(BuildContext context) => _openSchedule(context, mode: CalendarMode.weekly);

  static Future<void> openDaily(BuildContext context) => _openSchedule(context, mode: CalendarMode.daily);
}
