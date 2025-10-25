import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

class DeviceState {
  final Map<String, dynamic> values;

  const DeviceState(this.values);

  dynamic valueOf(String key) => values[key];

  DeviceState merge(Map<String, dynamic> delta) => DeviceState({...values, ...delta});
  static const empty = DeviceState({});
}

abstract class TelemetryRepository {
  Stream<Map<String, dynamic>> stream(String deviceId);
}

class TelemetryRepositoryMock implements TelemetryRepository {
  final _rand = Random();
  final _switchState = <String, bool>{};
  final _modeState = <String, String>{};

  @override
  Stream<Map<String, dynamic>> stream(String deviceId) async* {
    double current = 20 + _rand.nextDouble() * 2;
    double humidity = 60 + _rand.nextDouble() * 5;
    _switchState.putIfAbsent(deviceId, () => false);

    while (true) {
      await Future<void>.delayed(const Duration(seconds: 1));
      current += (_rand.nextDouble() - 0.5) * 0.3;
      humidity += (_rand.nextDouble() + 1) * 0.3;
      yield {
        'sensor.temperature': double.parse(current.toStringAsFixed(1)),
        'setting.target_temperature': 21.0,
        'switch.heating.state': _switchState[deviceId] ?? false,
        'schedule.next_target_temperature': 22.0,
        'schedule.next_time': "19:30",
        'climate.mode': _modeState[deviceId] ?? "manual",
        'sensor.humidity': double.parse(humidity.toStringAsFixed(1)),
        'sensor.power': 2000,
        'stats.heating_duty_24h': 0.5,
        'sensor.water_inlet_temp': 28.5,
        'sensor.water_outlet_temp': 30,
      };
    }
  }

  void setSwitch(String deviceId, bool v) => _switchState[deviceId] = v;

  void setMode(String deviceId, String mode) => _modeState[deviceId] = mode;
}

class DeviceStateCubit extends Cubit<DeviceState> {
  final TelemetryRepository telemetry;
  StreamSubscription? _sub;

  DeviceStateCubit(this.telemetry) : super(DeviceState.empty);

  void bindDevice(String deviceId) {
    _sub?.cancel();
    _sub = telemetry.stream(deviceId).listen((delta) => emit(state.merge(delta)));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
