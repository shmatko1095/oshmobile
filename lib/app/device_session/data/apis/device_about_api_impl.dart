import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:oshmobile/features/device_about/domain/repositories/device_about_repository.dart';
import 'package:oshmobile/app/device_session/domain/device_facade.dart';
import 'package:oshmobile/app/device_session/domain/device_snapshot.dart';

class DeviceAboutApiImpl implements DeviceAboutApi {
  final DeviceAboutRepository _repo;
  final VoidCallback _onChanged;

  final StreamController<Map<String, dynamic>> _stream =
      StreamController<Map<String, dynamic>>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _started = false;
  bool _disposed = false;

  Map<String, dynamic>? _current;
  DeviceSlice<Map<String, dynamic>> _slice =
      const DeviceSlice<Map<String, dynamic>>.idle();

  DeviceAboutApiImpl({
    required DeviceAboutRepository repo,
    required VoidCallback onChanged,
  })  : _repo = repo,
        _onChanged = onChanged;

  DeviceSlice<Map<String, dynamic>> get slice => _slice;

  void _setSlice(DeviceSlice<Map<String, dynamic>> next) {
    _slice = next;
    if (_current != null && !_stream.isClosed) {
      _stream.add(Map<String, dynamic>.from(_current!));
    }
    _onChanged();
  }

  Future<void> start() async {
    if (_disposed || _started) return;
    _started = true;

    if (_current == null) {
      _setSlice(const DeviceSlice<Map<String, dynamic>>.loading());
    }

    _sub = _repo.watchState().listen(
      (data) {
        _current = Map<String, dynamic>.from(data);
        _setSlice(DeviceSlice<Map<String, dynamic>>.ready(
          data: Map<String, dynamic>.from(_current!),
        ));
      },
      onError: (_) {
        _setSlice(DeviceSlice<Map<String, dynamic>>.error(
          data: _current == null ? null : Map<String, dynamic>.from(_current!),
          error: 'Failed to read device state',
        ));
      },
      cancelOnError: false,
    );
  }

  @override
  Map<String, dynamic>? get current {
    final data = _current;
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  @override
  Stream<Map<String, dynamic>> watch() {
    return Stream<Map<String, dynamic>>.multi((controller) {
      final cur = current;
      if (cur != null) {
        controller.add(cur);
      }

      final sub = _stream.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<Map<String, dynamic>?> get({bool force = false}) async {
    await start();
    return current;
  }

  @override
  Future<void> stop() async {
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;
    _started = false;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await stop();

    try {
      await _stream.close();
    } catch (_) {}
  }
}
