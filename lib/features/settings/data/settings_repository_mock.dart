import 'dart:async';

import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

/// In-memory mock implementation of [SettingsRepository].
///
/// This class:
/// - does NOT communicate over MQTT;
/// - keeps settings per deviceSn in a local Map;
/// - immediately acknowledges save operations via watchSnapshot stream.
///
/// It is useful while firmware does not yet support the real
/// shadow/settings topics.
class SettingsRepositoryMock implements SettingsRepository {
  /// Simulated network latency. Set to Duration.zero for instant responses.
  final Duration latency;

  final Map<String, SettingsSnapshot> _store = {};
  final Map<String, StreamController<MapEntry<String?, SettingsSnapshot>>> _controllers = {};

  SettingsRepositoryMock({this.latency = const Duration(milliseconds: 150)});

  @override
  Future<SettingsSnapshot> fetchAll(String deviceSn) async {
    await Future<void>.delayed(latency);

    final existing = _store[deviceSn];
    if (existing != null) {
      return existing;
    }

    final initial = _initialSnapshotFor(deviceSn);
    _store[deviceSn] = initial;

    // Also push initial snapshot to watchers, if any.
    final ctrl = _controllers[deviceSn];
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(MapEntry<String?, SettingsSnapshot>(null, initial));
    }

    return initial;
  }

  @override
  Future<void> saveAll(
    String deviceSn,
    SettingsSnapshot snapshot, {
    String? reqId,
  }) async {
    await Future<void>.delayed(latency);

    _store[deviceSn] = snapshot;

    final ctrl = _controllers[deviceSn];
    if (ctrl != null && !ctrl.isClosed) {
      // Emit updated snapshot with applied reqId to simulate ACK.
      ctrl.add(MapEntry<String?, SettingsSnapshot>(reqId, snapshot));
    }
  }

  @override
  Stream<MapEntry<String?, SettingsSnapshot>> watchSnapshot(String deviceSn) {
    final existing = _controllers[deviceSn];
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    // Declare first, assign later so we can safely use it in onListen.
    late final StreamController<MapEntry<String?, SettingsSnapshot>> ctrl;

    ctrl = StreamController<MapEntry<String?, SettingsSnapshot>>.broadcast(
      onListen: () {
        // On first listener, ensure we have an initial snapshot and emit it.
        final snap = _store[deviceSn] ?? _initialSnapshotFor(deviceSn);
        _store[deviceSn] = snap;
        ctrl.add(MapEntry<String?, SettingsSnapshot>(null, snap));
      },
    );

    _controllers[deviceSn] = ctrl;
    return ctrl.stream;
  }

  /// Returns initial mock snapshot for a given device.
  ///
  /// For now all devices share the same defaults:
  /// {
  ///   "display": {
  ///     "activeBrightness": 100,
  ///     "idleBrightness": 10,
  ///     "idleTime": 30,
  ///     "dimOnIdle": true
  ///   },
  ///   "update": {
  ///     "autoUpdateEnabled": false,
  ///     "updateAtMidnight": false,
  ///     "checkIntervalMin": 60
  ///   }
  /// }
  SettingsSnapshot _initialSnapshotFor(String deviceSn) {
    final json = <String, dynamic>{
      'display': {
        'activeBrightness': 100,
        'idleBrightness': 10,
        'idleTime': 30,
        'dimOnIdle': true,
      },
      'update': {
        'autoUpdateEnabled': false,
        'updateAtMidnight': false,
        'checkIntervalMin': 60,
      },
    };

    return SettingsSnapshot.fromJson(json);
  }

  /// Dispose all controllers. Useful in tests.
  Future<void> dispose() async {
    for (final c in _controllers.values) {
      await c.close();
    }
    _controllers.clear();
  }
}
