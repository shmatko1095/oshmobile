import 'dart:async';

import 'package:flutter/material.dart';

import '../../schedule/domain/models/schedule_models.dart';

/// Контракт репозитория расписания
abstract class ScheduleRepository {
  Future<List<SchedulePoint>> fetchSchedule(String deviceId, CalendarMode mode);
  Future<void> saveSchedule(String deviceId, CalendarMode mode, List<SchedulePoint> points);
}

/// Утилиты сериализации (пример формата для команды/бэка)
extension SchedulePointJson on SchedulePoint {
  Map<String, dynamic> toJson() => {
        't': _fmtTime(time), // "HH:mm"
        'v': temperature, // double
        'd': daysMask, // int (битовая маска)
      };

  static String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static SchedulePoint fromJson(Map<String, dynamic> j) => SchedulePoint(
        time: parseTime(j['t'] as String),
        temperature: (j['v'] as num).toDouble(),
        daysMask: j['d'] as int,
      );
}

/// Dev-реализация: хранит всё в памяти (для локальной разработки)
class InMemoryScheduleRepository implements ScheduleRepository {
  final Map<String, List<SchedulePoint>> _byKey = {};

  String _key(String deviceId, CalendarMode mode) => '$deviceId/${mode.name}';

  @override
  Future<List<SchedulePoint>> fetchSchedule(String deviceId, CalendarMode mode) async {
    final key = _key(deviceId, mode);
    await Future<void>.delayed(const Duration(milliseconds: 150)); // имитация сети
    return List<SchedulePoint>.from(_byKey[key] ?? _demo(mode));
  }

  @override
  Future<void> saveSchedule(String deviceId, CalendarMode mode, List<SchedulePoint> points) async {
    final key = _key(deviceId, mode);
    await Future<void>.delayed(const Duration(milliseconds: 150)); // имитация сети
    _byKey[key] = List<SchedulePoint>.from(points);
  }

  List<SchedulePoint> _demo(CalendarMode mode) {
    if (mode == CalendarMode.weekly) {
      return [
        SchedulePoint(
          time: const TimeOfDay(hour: 6, minute: 30),
          temperature: 20.0,
          daysMask: WeekdayMask.mon | WeekdayMask.tue | WeekdayMask.wed | WeekdayMask.thu | WeekdayMask.fri,
        ),
        SchedulePoint(
          time: const TimeOfDay(hour: 22, minute: 0),
          temperature: 18.5,
          daysMask: WeekdayMask.mon | WeekdayMask.tue | WeekdayMask.wed | WeekdayMask.thu | WeekdayMask.fri,
        ),
        SchedulePoint(
          time: const TimeOfDay(hour: 9, minute: 0),
          temperature: 21.5,
          daysMask: WeekdayMask.sat | WeekdayMask.sun,
        ),
      ];
    }
    // daily — без дней
    return [
      const SchedulePoint(time: TimeOfDay(hour: 7, minute: 0), temperature: 20.0, daysMask: 0),
      const SchedulePoint(time: TimeOfDay(hour: 22, minute: 0), temperature: 18.0, daysMask: 0),
    ];
  }
}

/// Скелет интеграции через DeviceActionsCubit (заполнение команд — под твой бэкенд)
/// Пример: отправляем целиком массив точек как JSON.
/// Для загрузки тебе вероятно пригодится отдельный use-case/запрос (или DeviceStateCubit).
class DeviceActionsScheduleRepository implements ScheduleRepository {
  final dynamic deviceActionsCubit; // тип: DeviceActionsCubit
  DeviceActionsScheduleRepository(this.deviceActionsCubit);

  @override
  Future<List<SchedulePoint>> fetchSchedule(String deviceId, CalendarMode mode) async {
    // TODO: заменить на реальный запрос (через твой Query/Repo).
    throw UnimplementedError('Plug your "get schedule" use-case here');
  }

  @override
  Future<void> saveSchedule(String deviceId, CalendarMode mode, List<SchedulePoint> points) async {
    final payload = points.map((e) => e.toJson()).toList();
    // Пример команды:
    // await deviceActionsCubit.sendCommand(deviceId, 'schedule.set',
    //   args: {'mode': mode.name, 'points': payload});
    await deviceActionsCubit.sendCommand(
      deviceId,
      'schedule.set',
      args: {'mode': mode.name, 'points': payload},
    );
  }
}
