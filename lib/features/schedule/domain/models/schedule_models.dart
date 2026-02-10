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

  static const on = CalendarMode('on');
  static const off = CalendarMode('off');
  static const antifreeze = CalendarMode('antifreeze');
  static const daily = CalendarMode('daily');
  static const weekly = CalendarMode('weekly');

  static const all = [off, antifreeze, on, daily, weekly];
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

  static int weekdayBit(DateTime dt) => 1 << ((dt.weekday - 1) % 7);

  /// Rotate single-bit weekday backwards (Mon -> Sun, Tue -> Mon, ...).
  static int prevDayBit(int dayBit) {
    // Monday is the lowest bit, Sunday is the highest.
    if (dayBit == WeekdayMask.mon) return WeekdayMask.sun;
    return dayBit >> 1;
  }

  /// Rotate single-bit weekday forwards (Sun -> Mon, Sat -> Sun, ...).
  static int nextDayBit(int dayBit) {
    if (dayBit == WeekdayMask.sun) return WeekdayMask.mon;
    return dayBit << 1;
  }
}

/// Unified schedule point (range). If [min]==[max], it's a fixed setpoint.
class SchedulePoint {
  final TimeOfDay time; // start time of this setpoint/range
  final int daysMask; // which days it applies to
  final double temp; // min target (antifreeze lower bound or setpoint)

  const SchedulePoint({
    required this.time,
    required this.daysMask,
    required this.temp,
  });

  SchedulePoint copyWith({
    TimeOfDay? time,
    int? daysMask,
    double? temp,
  }) =>
      SchedulePoint(
        time: time ?? this.time,
        daysMask: daysMask ?? this.daysMask,
        temp: temp ?? this.temp,
      );
}
