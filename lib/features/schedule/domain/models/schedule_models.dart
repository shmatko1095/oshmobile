import 'package:flutter/material.dart';

/// Calendar mode supported by the device.
enum CalendarMode { daily, weekly }

/// Bit masks for weekdays. Use any mapping you already have if different.
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

/// One schedule point: at [time] set thermostat to [temperature].
/// For weekly mode, [daysMask] defines applicable days (bitwise OR of WeekdayMask).
class SchedulePoint {
  final TimeOfDay time;
  final double temperature;
  final int daysMask;

  const SchedulePoint({
    required this.time,
    required this.temperature,
    required this.daysMask,
  });

  SchedulePoint copyWith({TimeOfDay? time, double? temperature, int? daysMask}) => SchedulePoint(
        time: time ?? this.time,
        temperature: temperature ?? this.temperature,
        daysMask: daysMask ?? this.daysMask,
      );

  /// Serialize for MQTT payloads. Device mapper expects these fields.
  Map<String, dynamic> toJson() => {
        't': _fmt(time), // "HH:mm"
        'temp': temperature, // double
        'daysMask': daysMask, // int (0 may mean "all" for daily mode)
      };

  static SchedulePoint fromJson(Map<String, dynamic> j) {
    final hhmm = (j['t'] as String?) ?? '00:00';
    final parts = hhmm.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final temp = (j['temp'] as num?)?.toDouble() ?? 0.0;
    final mask = (j['daysMask'] as int?) ?? 0;
    return SchedulePoint(
        time: TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59)), temperature: temp, daysMask: mask);
  }
}

String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
