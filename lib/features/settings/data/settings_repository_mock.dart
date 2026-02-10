import 'dart:async';

import 'package:oshmobile/features/settings/data/settings_jsonrpc_codec.dart';
import 'package:oshmobile/features/settings/domain/models/settings_snapshot.dart';
import 'package:oshmobile/features/settings/domain/repositories/settings_repository.dart';

/// In-memory mock implementation of [SettingsRepository].
///
/// This class:
/// - does NOT communicate over MQTT;
/// - keeps settings in memory;
/// - immediately acknowledges save operations via watchSnapshot stream.
class SettingsRepositoryMock implements SettingsRepository {
  /// Simulated network latency. Set to Duration.zero for instant responses.
  final Duration latency;

  SettingsSnapshot? _snapshot;
  StreamController<SettingsSnapshot>? _controller;

  SettingsRepositoryMock({this.latency = const Duration(milliseconds: 150)});

  @override
  Future<SettingsSnapshot> fetchAll({bool forceGet = false}) async {
    await Future<void>.delayed(latency);

    final existing = _snapshot;
    if (existing != null) {
      return existing;
    }

    final initial = _initialSnapshot();
    _snapshot = initial;

    // Also push initial snapshot to watchers, if any.
    final ctrl = _controller;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(initial);
    }

    return initial;
  }

  @override
  Future<void> saveAll(
    SettingsSnapshot snapshot, {
    String? reqId,
  }) async {
    await Future<void>.delayed(latency);

    _snapshot = snapshot;

    final ctrl = _controller;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(snapshot);
    }
  }

  @override
  Future<void> patch(Map<String, dynamic> patch, {String? reqId}) async {
    await Future<void>.delayed(latency);

    final data = SettingsJsonRpcCodec.encodePatch(patch);
    final current = _snapshot ?? _initialSnapshot();
    final next = current.merged(data);
    _snapshot = next;

    final ctrl = _controller;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(next);
    }
  }

  @override
  Stream<SettingsSnapshot> watchSnapshot() {
    final existing = _controller;
    if (existing != null && !existing.isClosed) {
      return existing.stream;
    }

    // Declare first, assign later so we can safely use it in onListen.
    late final StreamController<SettingsSnapshot> ctrl;

    ctrl = StreamController<SettingsSnapshot>.broadcast(
      onListen: () {
        // On first listener, ensure we have an initial snapshot and emit it.
        final snap = _snapshot ?? _initialSnapshot();
        _snapshot = snap;
        ctrl.add(snap);
      },
    );

    _controller = ctrl;
    return ctrl.stream;
  }

  SettingsSnapshot _initialSnapshot() {
    final json = <String, dynamic>{
      'display': {
        'activeBrightness': 100,
        'idleBrightness': 10,
        'idleTime': 30,
        'dimOnIdle': true,
        'language': 'en',
      },
      'update': {
        'autoUpdateEnabled': false,
        'updateAtMidnight': false,
        'checkIntervalMin': 60,
      },
      'time': {
        'auto': true,
        'timeZone': 0,
      },
    };

    return SettingsSnapshot.fromJson(json);
  }

  /// Dispose all controllers. Useful in tests.
  Future<void> dispose() async {
    final ctrl = _controller;
    if (ctrl != null) {
      await ctrl.close();
    }
    _controller = null;
  }
}
