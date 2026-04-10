import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:oshmobile/core/analytics/osh_analytics.dart';
import 'package:oshmobile/core/analytics/osh_analytics_events.dart';
import 'package:oshmobile/core/analytics/osh_analytics_screens.dart';
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
    return openForMode(
      context,
      mode,
      source: 'hero_panel',
    );
  }

  static Future<void> openForMode(
    BuildContext context,
    CalendarMode mode, {
    required String source,
  }) async {
    if (mode == CalendarMode.off) return;
    if (mode == CalendarMode.on) {
      return _openOn(context, source: source);
    }
    if (mode == CalendarMode.range) {
      return _openRange(context, source: source);
    }
    if (mode == CalendarMode.daily || mode == CalendarMode.weekly) {
      return _openSchedule(context, mode: mode, source: source);
    }
  }

  static Future<void> _openOn(
    BuildContext context, {
    required String source,
  }) async {
    final s = S.of(context);
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

    await OshAnalytics.logEvent(
      OshAnalyticsEvents.scheduleEditorOpened,
      parameters: {
        'mode': CalendarMode.on.id,
        'source': source,
      },
    );
    if (!context.mounted) return;
    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            settings: const RouteSettings(
              name: OshAnalyticsScreens.manualTemperature,
            ),
            builder: (_) => DeviceRouteScope.provide(
              facade: facade,
              snapshotCubit: snapshotCubit,
              child: ManualTemperaturePage(
                initial: initial,
                title: s.ManualTemperature,
                onSave: (value) {
                  final point = SchedulePoint(
                    time: const TimeOfDay(hour: 0, minute: 0),
                    daysMask: WeekdayMask.all,
                    temp: value,
                  );
                  facade.schedule.commandSetMode(
                    CalendarMode.on,
                    source: 'mode_editor',
                  );
                  facade.schedule.patchList(CalendarMode.on, [point]);
                },
              ),
            ),
          ),
        )
        .then((_) => facade.schedule.save());
  }

  static Future<void> _openRange(
    BuildContext context, {
    required String source,
  }) async {
    final s = S.of(context);
    final facade = context.read<DeviceFacade>();
    final snapshotCubit = context.read<DeviceSnapshotCubit>();
    final snap = facade.schedule.current ?? await facade.schedule.get();
    if (!context.mounted) return;

    double minInit = snap.range.min;
    double maxInit = snap.range.max;

    await OshAnalytics.logEvent(
      OshAnalyticsEvents.scheduleEditorOpened,
      parameters: {
        'mode': CalendarMode.range.id,
        'source': source,
      },
    );
    if (!context.mounted) return;
    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            settings: const RouteSettings(
              name: OshAnalyticsScreens.scheduleRange,
            ),
            builder: (_) => DeviceRouteScope.provide(
              facade: facade,
              snapshotCubit: snapshotCubit,
              child: ScheduleRangePage(
                initialMin: minInit,
                initialMax: maxInit,
                title: s.ModeRange,
                onSave: (minValue, maxValue) {
                  final lo = (minValue <= maxValue) ? minValue : maxValue;
                  final hi = (maxValue >= minValue) ? maxValue : minValue;
                  facade.schedule.patchRange(
                    ScheduleRange(
                      min: double.parse(lo.toStringAsFixed(1)),
                      max: double.parse(hi.toStringAsFixed(1)),
                    ),
                  );
                  facade.schedule.commandSetMode(
                    CalendarMode.range,
                    source: 'mode_editor',
                  );
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
    required String source,
  }) async {
    final s = S.of(context);
    final facade = context.read<DeviceFacade>();
    final snapshotCubit = context.read<DeviceSnapshotCubit>();
    final title =
        (mode.id == CalendarMode.weekly.id) ? s.ModeWeekly : s.ModeDaily;

    await OshAnalytics.logEvent(
      OshAnalyticsEvents.scheduleEditorOpened,
      parameters: {
        'mode': mode.id,
        'source': source,
      },
    );
    if (!context.mounted) return;
    await Navigator.of(context)
        .push(
          MaterialPageRoute(
            settings: const RouteSettings(
              name: OshAnalyticsScreens.scheduleEditor,
            ),
            builder: (_) => DeviceRouteScope.provide(
              facade: facade,
              snapshotCubit: snapshotCubit,
              child: ScheduleEditorPage(
                title: title,
                mode: mode,
              ),
            ),
          ),
        )
        .then((_) => facade.schedule.save());
  }

  static Future<void> openOn(BuildContext context) =>
      _openOn(context, source: 'unknown');

  static Future<void> openRange(BuildContext context) =>
      _openRange(context, source: 'unknown');

  static Future<void> openWeekly(BuildContext context) => _openSchedule(
        context,
        mode: CalendarMode.weekly,
        source: 'unknown',
      );

  static Future<void> openDaily(BuildContext context) => _openSchedule(
        context,
        mode: CalendarMode.daily,
        source: 'unknown',
      );
}
