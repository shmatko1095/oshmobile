import 'package:flutter/material.dart';

/// Режим расписания
enum CalendarMode { daily, weekly }

/// Точка расписания: время, целевая температура, битовая маска дней (Пн..Вс)
class SchedulePoint {
  final TimeOfDay time;
  final double temperature;
  final int daysMask; // 7 бит: Пн..Вс

  const SchedulePoint({
    required this.time,
    required this.temperature,
    required this.daysMask,
  });

  SchedulePoint copyWith({
    TimeOfDay? time,
    double? temperature,
    int? daysMask,
  }) {
    return SchedulePoint(
      time: time ?? this.time,
      temperature: temperature ?? this.temperature,
      daysMask: daysMask ?? this.daysMask,
    );
  }
}

/// Битовая маска дней недели (Пн..Вс)
class WeekdayMask {
  static const int mon = 1 << 0;
  static const int tue = 1 << 1;
  static const int wed = 1 << 2;
  static const int thu = 1 << 3;
  static const int fri = 1 << 4;
  static const int sat = 1 << 5;
  static const int sun = 1 << 6;

  static const List<int> order = [mon, tue, wed, thu, fri, sat, sun];

  static bool has(int mask, int dayBit) => (mask & dayBit) != 0;

  static int toggle(int mask, int dayBit) => mask ^ dayBit;

  static String shortLabel(int dayBit) {
    switch (dayBit) {
      case mon:
        return 'Mon';
      case tue:
        return 'Tue';
      case wed:
        return 'Wed';
      case thu:
        return 'Thu';
      case fri:
        return 'Fri';
      case sat:
        return 'Sat';
      case sun:
        return 'Sun';
      default:
        return '?';
    }
  }
}
