// import 'dart:async';
// import 'dart:math';
//
// abstract class TelemetryRepository {
//   Stream<Map<String, dynamic>> stream(String deviceId);
// }
//
// class TelemetryRepositoryMock implements TelemetryRepository {
//   final _rand = Random();
//
//   // внешнее состояние, на которое может влиять UI/команды
//   final _switchState = <String, bool>{}; // switch.heating.state
//   final _modeState = <String, String>{}; // climate.mode
//   final _targetState = <String, double>{}; // setting.target_temperature
//
//   // внутреннее физическое состояние по девайсу
//   final _sim = <String, _SimState>{};
//
//   @override
//   Stream<Map<String, dynamic>> stream(String deviceId) async* {
//     final s = _sim.putIfAbsent(deviceId, () => _SimState(_rand));
//
//     // дефолты внешних флагов
//     _switchState.putIfAbsent(deviceId, () => false);
//     _modeState.putIfAbsent(deviceId, () => 'manual');
//     _targetState.putIfAbsent(deviceId, () => 21.0);
//
//     // тики раз в секунду
//     const dt = Duration(seconds: 1);
//     final dtSec = dt.inSeconds.toDouble();
//
//     // --- model params (подберите под вкус) ---
//     const double tempGainOn = 0.06; // скорость подтягивания к target при нагреве
//     const double tempGainOff = 0.006; // скорость к ambient без нагрева
//     const double tempNoiseAmp = 0.03; // шум °C за тик
//
//     const double humAmbient = 45.0; // окружающая влажность
//     const double humMeanRevert = 0.005;
//     const double humNoiseAmp = 0.25; // шум %RH за тик
//     const double tempHumCoupling = 0.5; // рост T сушит воздух
//
//     const double maxPowerW = 2500; // пиковая мощность
//     const double dutyTauSec = 86400; // 24ч EMA
//     final double dutyAlpha = dtSec / dutyTauSec;
//
//     // вода
//     const double waterAmbient = 18.0;
//     const double inletAmbientGain = 0.01; // к окружающей
//     const double inletRoomGain = 0.004; // подсос от комнатной
//     const double outletFollowGain = 0.12; // насколько быстро следует к "желаемой" дельте
//     const double maxDeltaTDesired = 8.0; // макс дельта T между выходом и входом при сильном нагреве
//
//     while (true) {
//       await Future<void>.delayed(dt);
//
//       final heaterOn = _switchState[deviceId] ?? false;
//       final modeRaw = _modeState[deviceId] ?? 'manual';
//       final target = _targetState[deviceId] ?? 21.0;
//
//       // --- Температура ---
//       final prevT = s.roomTemp;
//       if (heaterOn) {
//         // тянем к цели + шум
//         s.roomTemp += (target - s.roomTemp) * (tempGainOn * dtSec) + (_rand.nextDouble() - 0.5) * tempNoiseAmp;
//       } else {
//         // без нагрева: к ambient + шум
//         s.roomTemp += (s.ambientTemp - s.roomTemp) * (tempGainOff * dtSec) + (_rand.nextDouble() - 0.5) * tempNoiseAmp;
//       }
//       s.roomTemp = s.roomTemp.clamp(5.0, 35.0);
//
//       // --- Влажность ---
//       final dT = s.roomTemp - prevT;
//       s.humidity += (humAmbient - s.humidity) * (humMeanRevert * dtSec) +
//           (_rand.nextDouble() - 0.5) * humNoiseAmp -
//           tempHumCoupling * dT;
//       s.humidity = s.humidity.clamp(20.0, 85.0);
//
//       // --- Мощность ---
//       // если нагрев включён — мощность зависит от того, насколько далеки от цели
//       double demand = 0;
//       if (heaterOn) {
//         // нормируем расстояние до цели в 0..1 (5°C зазор -> ~макс мощность)
//         demand = ((target - s.roomTemp) / 5.0).clamp(0.0, 1.0);
//       }
//       s.powerW = demand > 0
//           ? (maxPowerW * (0.15 + 0.85 * demand)) // удерживаем минимальный порог когда включен
//           : 0.0;
//       // небольшой шум на мощность
//       if (s.powerW > 0) {
//         s.powerW += (_rand.nextDouble() - 0.5) * 60.0;
//         s.powerW = s.powerW.clamp(200.0, maxPowerW);
//       }
//
//       // --- Duty-cycle за 24ч (EMA) ---
//       final onAs01 = heaterOn ? 1.0 : 0.0;
//       s.duty24h = (1 - dutyAlpha) * s.duty24h + dutyAlpha * onAs01;
//
//       // --- Вода (впуск/выпуск) ---
//       // вход: тянется к окружающей воде + немного под влиянием комнаты
//       s.inlet = s.inlet + (waterAmbient - s.inlet) * inletAmbientGain + (s.roomTemp - s.inlet) * inletRoomGain;
//       // желаемая дельта выхода: растёт с "насколько ниже цели" (0..maxDeltaT)
//       final deltaDesired = heaterOn ? (maxDeltaTDesired * ((target - s.roomTemp) / 6.0).clamp(0.0, 1.0)) : 0.0;
//       final outletDesired = s.inlet + deltaDesired;
//       s.outlet += (outletDesired - s.outlet) * outletFollowGain;
//       // небольшой шум
//       s.inlet += (_rand.nextDouble() - 0.5) * 0.05;
//       s.outlet += (_rand.nextDouble() - 0.5) * 0.05;
//
//       // округления для UI (как у вас)
//       final tempOut = double.parse(s.roomTemp.toStringAsFixed(1));
//       final humOut = double.parse(s.humidity.toStringAsFixed(1));
//       final inletOut = double.parse(s.inlet.toStringAsFixed(1));
//       final outletOut = double.parse(s.outlet.toStringAsFixed(1));
//
//       // заглушки "следующей точки" (можете подменить из реального календаря)
//       final nextTemp = target + 1.0;
//       const nextTime = "19:30";
//
//       yield {
//         'sensor.temperature': tempOut,
//         'setting.target_temperature': target,
//         'switch.heating.state': heaterOn,
//         'climate.mode': modeRaw,
//         'sensor.humidity': humOut,
//
//         'sensor.power': s.powerW.round(), // Вт
//         'stats.heating_duty_24h': s.duty24h, // 0..1
//
//         'sensor.water_inlet_temp': inletOut,
//         'sensor.water_outlet_temp': outletOut,
//
//         'schedule.next_target_temperature': double.parse(nextTemp.toStringAsFixed(1)),
//         'schedule.next_time': nextTime,
//       };
//     }
//   }
//
//   // внешние «команды»
//   void setSwitch(String deviceId, bool v) => _switchState[deviceId] = v;
//   void setMode(String deviceId, String mode) => _modeState[deviceId] = mode;
//   void setTarget(String deviceId, double value) => _targetState[deviceId] = value;
// }
//
// /// внутреннее состояние симулятора для конкретного устройства
// class _SimState {
//   _SimState(Random r)
//       : ambientTemp = 19.0 + r.nextDouble() * 3.0,
//         roomTemp = 20.0 + r.nextDouble() * 2.0,
//         humidity = 45.0 + r.nextDouble() * 10.0,
//         inlet = 18.0 + r.nextDouble() * 1.5,
//         outlet = 19.0 + r.nextDouble() * 1.5;
//
//   final double ambientTemp; // «улица/коробка»
//   double roomTemp; // текущая комната
//   double humidity; // %RH
//
//   double inlet; // вход воды
//   double outlet; // выход воды
//
//   double powerW = 0.0; // текущая мощность, Вт
//   double duty24h = 0.0; // EMA 24h (0..1)
// }
