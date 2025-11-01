import 'package:flutter/material.dart';

/// Calendar mode supported by the device.
class CalendarMode {
  final String id;

  const CalendarMode(this.id);

  // Equality by id so different instances with same id are equal.
  @override
  bool operator ==(Object other) => other is CalendarMode && other.id == id;

  @override
  int get hashCode => id.hashCode;

  static const off = CalendarMode('off');
  static const antifreeze = CalendarMode('antifreeze');
  static const manual = CalendarMode('manual');
  static const daily = CalendarMode('daily');
  static const weekly = CalendarMode('weekly');

  static const all = [off, antifreeze, manual, daily, weekly];
}

/// Bit masks for weekdays. Use any mapping you already have if different.
class WeekdayMask {
  static const int mon = 1 << 0;
  static const int tue = 1 << 1;
  static const int wed = 1 << 2;
  static const int thu = 1 << 3;
  static const int fri = 1 << 4;
  static const int sat = 1 << 5;
  static const int sun = 1 << 6;

  static const int all = mon | tue | wed | thu | fri | sat | sun;

  static bool includes(int mask, int weekday1Mon7Sun) {
    final bit = 1 << ((weekday1Mon7Sun - 1) % 7);
    return (mask & bit) != 0;
  }

  static const List<int> order = [mon, tue, wed, thu, fri, sat, sun];

  static bool has(int mask, int dayBit) => (mask & dayBit) != 0;

  static int toggle(int mask, int dayBit) => mask ^ dayBit;
}

/// Unified schedule point (range). If [min]==[max], it's a fixed setpoint.
class SchedulePoint {
  final TimeOfDay time; // start time of this setpoint/range
  final int daysMask; // which days it applies to
  final double min; // min target (antifreeze lower bound or setpoint)
  final double max; // max target (antifreeze upper bound or setpoint)

  const SchedulePoint({
    required this.time,
    required this.daysMask,
    required this.min,
    required this.max,
  });

  bool get isRange => min < max;

  SchedulePoint copyWith({
    TimeOfDay? time,
    int? daysMask,
    double? min,
    double? max,
  }) =>
      SchedulePoint(
        time: time ?? this.time,
        daysMask: daysMask ?? this.daysMask,
        min: min ?? this.min,
        max: max ?? this.max,
      );
}
