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

  @override
  Stream<Map<String, dynamic>> stream(String deviceId) async* {
    double current = 20 + _rand.nextDouble() * 2;
    _switchState.putIfAbsent(deviceId, () => false);

    while (true) {
      await Future<void>.delayed(const Duration(seconds: 1));
      current += (_rand.nextDouble() - 0.5) * 0.3;
      yield {
        'sensor.temperature': double.parse(current.toStringAsFixed(1)),
        'setting.target_temperature': 21.0,
        'switch.heating.state': _switchState[deviceId] ?? false,
      };
    }
  }

  void setSwitch(String deviceId, bool v) => _switchState[deviceId] = v;
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
