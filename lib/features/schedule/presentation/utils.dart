import 'package:flutter/material.dart';
import 'package:oshmobile/features/schedule/domain/models/schedule_models.dart';
import 'package:oshmobile/generated/l10n.dart';

String labelForCalendarMode(BuildContext context, final CalendarMode mode) {
  final s = S.of(context);
  switch (mode) {
    case CalendarMode.off:
      return s.ModeOff;
    case CalendarMode.range:
      return s.ModeRange;
    case CalendarMode.on:
      return s.ModeOn;
    case CalendarMode.daily:
      return s.ModeDaily;
    case CalendarMode.weekly:
      return s.ModeWeekly;
    default:
      return mode.id;
  }
}

String shortLabel(BuildContext context, final int dayBit) {
  final s = S.of(context);
  switch (dayBit) {
    case WeekdayMask.mon:
      return s.MonShort;
    case WeekdayMask.tue:
      return s.TueShort;
    case WeekdayMask.wed:
      return s.WedShort;
    case WeekdayMask.thu:
      return s.ThuShort;
    case WeekdayMask.fri:
      return s.FriShort;
    case WeekdayMask.sat:
      return s.SatShort;
    case WeekdayMask.sun:
      return s.SunShort;
    default:
      return '?';
  }
}
