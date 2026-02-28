import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:oshmobile/core/network/mqtt/protocol/v1/sensors_models.dart';
import 'package:oshmobile/features/devices/details/domain/repositories/telemetry_repository.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';

class DeviceTelemetryApiImpl implements DeviceTelemetryApi {
  final TelemetryRepository _repo;
  final VoidCallback _onChanged;

  final StreamController<Map<String, dynamic>> _stream =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamSubscription<TelemetryState>? _sub;
  bool _started = false;
  bool _disposed = false;

  Map<String, dynamic> _data = <String, dynamic>{};
  DeviceSlice<Map<String, dynamic>> _slice =
      const DeviceSlice<Map<String, dynamic>>.idle(
    data: <String, dynamic>{},
  );

  DeviceTelemetryApiImpl({
    required TelemetryRepository repo,
    required VoidCallback onChanged,
  })  : _repo = repo,
        _onChanged = onChanged;

  DeviceSlice<Map<String, dynamic>> get slice => _slice;
  TelemetryState? get rawCurrent => _repo.currentState;

  void _setSlice(DeviceSlice<Map<String, dynamic>> next) {
    _slice = next;
    if (!_stream.isClosed) {
      _stream.add(Map<String, dynamic>.from(_data));
    }
    _onChanged();
  }

  Future<void> start() async {
    if (_disposed || _started) return;
    _started = true;

    _setSlice(DeviceSlice<Map<String, dynamic>>.loading(
      data: Map<String, dynamic>.from(_data),
    ));

    try {
      await _repo.subscribe();
    } catch (e) {
      _setSlice(DeviceSlice<Map<String, dynamic>>.error(
        data: Map<String, dynamic>.from(_data),
        error: e.toString(),
      ));
      return;
    }

    _sub = _repo.watchState().listen(
      (state) {
        _data = _serialize(state);
        _setSlice(DeviceSlice<Map<String, dynamic>>.ready(
          data: Map<String, dynamic>.from(_data),
        ));
      },
      onError: (_) {
        _setSlice(DeviceSlice<Map<String, dynamic>>.error(
          data: Map<String, dynamic>.from(_data),
          error: 'Telemetry stream degraded',
        ));
      },
      cancelOnError: false,
    );
  }

  @override
  Map<String, dynamic> get current => Map<String, dynamic>.from(_data);

  @override
  Stream<Map<String, dynamic>> watch() {
    return Stream<Map<String, dynamic>>.multi((controller) {
      controller.add(current);

      final sub = _stream.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<Map<String, dynamic>> get({bool force = false}) async {
    await start();

    if (force || _data.isEmpty) {
      try {
        final state = await _repo.fetch();
        _data = _serialize(state);
        _setSlice(DeviceSlice<Map<String, dynamic>>.ready(
          data: Map<String, dynamic>.from(_data),
        ));
      } catch (e) {
        _setSlice(DeviceSlice<Map<String, dynamic>>.error(
          data: Map<String, dynamic>.from(_data),
          error:
              e is TimeoutException ? (e.message ?? 'Timeout') : e.toString(),
        ));
      }
    }

    return current;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    try {
      await _sub?.cancel();
    } catch (_) {}

    try {
      await _repo.unsubscribe();
    } catch (_) {}

    try {
      await _stream.close();
    } catch (_) {}
  }

  Map<String, dynamic> _serialize(TelemetryState state) {
    return <String, dynamic>{
      'climate_sensors': [
        for (final item in state.climateSensors)
          <String, dynamic>{
            'id': item.id,
            'temp_valid': item.tempValid,
            'humidity_valid': item.humidityValid,
            if (item.temp != null) 'temp': item.temp,
            if (item.humidity != null) 'humidity': item.humidity,
          },
      ],
      'heater_enabled': state.heaterEnabled,
      'load_factor': state.loadFactor,
    };
  }
}
