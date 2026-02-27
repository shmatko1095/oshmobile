import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/app/device_session/scopes/device_route_scope.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/presentation/cubit/device_snapshot_cubit.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/features/schedule/domain/utils/schedule_point_resolver.dart';
import 'package:oshmobile/features/schedule/presentation/pages/manual_temperature_page.dart';
import 'package:oshmobile/features/schedule/presentation/pages/range_page.dart';
import 'package:oshmobile/features/schedule/presentation/pages/schedule_editor_page.dart';
import 'package:oshmobile/generated/l10n.dart';

class ThermostatModeNavigator {
  static Future<void> openForCurrentMode(BuildContext context) async {
    final facade = context.read<DeviceFacade>();
    final mode = facade.schedule.current?.mode ?? CalendarMode.off;

    if (mode == CalendarMode.on) {
      return _openOn(context);
    }
    if (mode == CalendarMode.range) {
      return _openRange(context);
    }
    if (mode == CalendarMode.daily || mode == CalendarMode.weekly) {
      return _openSchedule(context, mode: mode);
    }
  }

  static Future<void> _openOn(BuildContext context) async {
    final facade = context.read<DeviceFacade>();
    final snapshotCubit = context.read<DeviceSnapshotCubit>();
    var initial = 21.0;

    final snap = facade.schedule.current ?? await facade.schedule.get();
    final manual = snap.pointsFor(CalendarMode.on);
    final point = manual.isNotEmpty ? manual.first : resolveCurrentPoint(snap);
    if (point != null) {
      initial = point.temp;
    }
    if (!context.mounted) return;

    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DeviceRouteScope.provide(
              facade: facade,
              snapshotCubit: snapshotCubit,
              child: ManualTemperaturePage(
                initial: initial,
                title: S.of(context).ManualTemperature,
                onSave: (value) {
                  final point = SchedulePoint(
                    time: const TimeOfDay(hour: 0, minute: 0),
                    daysMask: WeekdayMask.all,
                    temp: value,
                  );
                  facade.schedule.commandSetMode(CalendarMode.on);
                  facade.schedule.patchList(CalendarMode.on, [point]);
                },
              ),
            ),
          ),
        )
        .then((_) => facade.schedule.save());
  }

  static Future<void> _openRange(BuildContext context) async {
    final facade = context.read<DeviceFacade>();
    final snapshotCubit = context.read<DeviceSnapshotCubit>();
    final snap = facade.schedule.current ?? await facade.schedule.get();
    if (!context.mounted) return;

    double minInit = snap.range.min;
    double maxInit = snap.range.max;

    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DeviceRouteScope.provide(
              facade: facade,
              snapshotCubit: snapshotCubit,
              child: ScheduleRangePage(
                initialMin: minInit,
                initialMax: maxInit,
                title: S.of(context).ModeRange,
                onSave: (minValue, maxValue) {
                  final lo = (minValue <= maxValue) ? minValue : maxValue;
                  final hi = (maxValue >= minValue) ? maxValue : minValue;
                  facade.schedule.patchRange(
                    ScheduleRange(
                      min: double.parse(lo.toStringAsFixed(1)),
                      max: double.parse(hi.toStringAsFixed(1)),
                    ),
                  );
                  facade.schedule.commandSetMode(CalendarMode.range);
                },
              ),
            ),
          ),
        )
        .then((_) => facade.schedule.save());
  }

  static Future<void> _openSchedule(
    BuildContext context, {
    required CalendarMode mode,
  }) async {
    final facade = context.read<DeviceFacade>();
    final snapshotCubit = context.read<DeviceSnapshotCubit>();
    final title = (mode.id == CalendarMode.weekly.id)
        ? S.of(context).ModeWeekly
        : S.of(context).ModeDaily;

    await facade.schedule.commandSetMode(mode);
    if (!context.mounted) return;

    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => DeviceRouteScope.provide(
              facade: facade,
              snapshotCubit: snapshotCubit,
              child: ScheduleEditorPage(title: title),
            ),
          ),
        )
        .then((_) => facade.schedule.save());
  }

  static Future<void> openOn(BuildContext context) => _openOn(context);

  static Future<void> openRange(BuildContext context) => _openRange(context);

  static Future<void> openWeekly(BuildContext context) =>
      _openSchedule(context, mode: CalendarMode.weekly);

  static Future<void> openDaily(BuildContext context) =>
      _openSchedule(context, mode: CalendarMode.daily);
}
