import 'dart:async';

import '../../schedule/domain/models/schedule_models.dart';

abstract class ScheduleRepository {
  /// Fetch the current schedule snapshot (retained) for [mode].
  Future<List<SchedulePoint>> fetchSchedule(String deviceId, CalendarMode mode);

  /// Persist schedule for [mode]. Implementation may wait for an ACK via reported shadow.
  Future<void> saveSchedule(String deviceId, CalendarMode mode, List<SchedulePoint> points);
}
//
// /// Утилиты сериализации (пример формата для команды/бэка)
// extension SchedulePointJson on SchedulePoint {
//   Map<String, dynamic> toJson() => {
//         't': _fmtTime(time), // "HH:mm"
//         'v': temperature, // double
//         'd': daysMask, // int (битовая маска)
//       };
//
//   static String _fmtTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
//
//   static TimeOfDay parseTime(String hhmm) {
//     final parts = hhmm.split(':');
//     return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
//   }
//
//   static SchedulePoint fromJson(Map<String, dynamic> j) => SchedulePoint(
//         time: parseTime(j['t'] as String),
//         temperature: (j['v'] as num).toDouble(),
//         daysMask: j['d'] as int,
//       );
// }
//
// /// Скелет интеграции через DeviceActionsCubit (заполнение команд — под твой бэкенд)
// /// Пример: отправляем целиком массив точек как JSON.
// /// Для загрузки тебе вероятно пригодится отдельный use-case/запрос (или DeviceStateCubit).
// class DeviceActionsScheduleRepository implements ScheduleRepository {
//   final dynamic deviceActionsCubit; // тип: DeviceActionsCubit
//   DeviceActionsScheduleRepository(this.deviceActionsCubit);
//
//   @override
//   Future<List<SchedulePoint>> fetchSchedule(String deviceId, CalendarMode mode) async {
//     // TODO: заменить на реальный запрос (через твой Query/Repo).
//     throw UnimplementedError('Plug your "get schedule" use-case here');
//   }
//
//   @override
//   Future<void> saveSchedule(String deviceId, CalendarMode mode, List<SchedulePoint> points) async {
//     final payload = points.map((e) => e.toJson()).toList();
//     // Пример команды:
//     // await deviceActionsCubit.sendCommand(deviceId, 'schedule.set',
//     //   args: {'mode': mode.name, 'points': payload});
//     await deviceActionsCubit.sendCommand(
//       deviceId,
//       'schedule.set',
//       args: {'mode': mode.name, 'points': payload},
//     );
//   }
// }
