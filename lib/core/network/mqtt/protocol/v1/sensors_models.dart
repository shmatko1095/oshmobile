import 'json_utils.dart';

import 'climate_sensor_telemetry.dart';

export 'climate_sensor_telemetry.dart';
export 'telemetry_state.dart';

class SensorPairing {
  final bool enabled;
  final String transport;
  final int timeoutSec;
  final int startedTs;

  const SensorPairing({
    required this.enabled,
    required this.transport,
    required this.timeoutSec,
    required this.startedTs,
  });

  static SensorPairing? fromJson(Map<String, dynamic> json) {
    final enabled = asBool(json['enabled']);
    final transport = asString(json['transport']);
    final timeoutSec = asInt(json['timeout_sec']);
    final startedTs = asInt(json['started_ts']);

    if (enabled == null ||
        transport == null ||
        timeoutSec == null ||
        startedTs == null) {
      return null;
    }

    return SensorPairing(
      enabled: enabled,
      transport: transport,
      timeoutSec: timeoutSec,
      startedTs: startedTs,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'transport': transport,
        'timeout_sec': timeoutSec,
        'started_ts': startedTs,
      };
}

class SensorMeta {
  final String id;
  final String name;
  final bool ref;
  final String transport;
  final bool removable;
  final String kind;

  const SensorMeta({
    required this.id,
    required this.name,
    required this.ref,
    required this.transport,
    required this.removable,
    required this.kind,
  });

  static SensorMeta? fromJson(Map<String, dynamic> json) {
    final id = asString(json['id']);
    final name = asString(json['name']);
    final ref = asBool(json['ref']);
    final transport = asString(json['transport']);
    final removable = asBool(json['removable']);
    final kind = asString(json['kind']);

    if (id == null ||
        name == null ||
        ref == null ||
        transport == null ||
        removable == null ||
        kind == null) {
      return null;
    }

    return SensorMeta(
      id: id,
      name: name,
      ref: ref,
      transport: transport,
      removable: removable,
      kind: kind,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ref': ref,
        'transport': transport,
        'removable': removable,
        'kind': kind,
      };
}

class SensorsState {
  final SensorPairing pairing;
  final List<SensorMeta> items;

  const SensorsState({
    required this.pairing,
    required this.items,
  });

  static SensorsState? fromJson(Map<String, dynamic> json) {
    final pairingRaw = json['pairing'];
    final itemsRaw = json['items'];
    if (pairingRaw is! Map || itemsRaw is! List) return null;

    final pairing = SensorPairing.fromJson(pairingRaw.cast<String, dynamic>());
    if (pairing == null) return null;

    final items = <SensorMeta>[];
    for (final item in itemsRaw) {
      if (item is! Map) return null;
      final parsed = SensorMeta.fromJson(item.cast<String, dynamic>());
      if (parsed == null) return null;
      items.add(parsed);
    }

    return SensorsState(pairing: pairing, items: items);
  }

  Map<String, dynamic> toJson() => {
        'pairing': pairing.toJson(),
        'items': [for (final item in items) item.toJson()],
      };
}

class SensorsSetItem {
  final String id;
  final String name;
  final bool ref;

  const SensorsSetItem({
    required this.id,
    required this.name,
    required this.ref,
  });

  static SensorsSetItem? fromJson(Map<String, dynamic> json) {
    final id = asString(json['id']);
    final name = asString(json['name']);
    final ref = asBool(json['ref']);
    if (id == null || name == null || ref == null) return null;

    return SensorsSetItem(id: id, name: name, ref: ref);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ref': ref,
      };
}

class SensorsSetPayload {
  final List<SensorsSetItem> items;

  const SensorsSetPayload({required this.items});

  Map<String, dynamic> toJson() => {
        'items': [for (final item in items) item.toJson()],
      };
}

abstract class SensorsPatch {
  const SensorsPatch();

  Map<String, dynamic> toJson();
}

class SensorsPatchRename extends SensorsPatch {
  final String id;
  final String name;

  const SensorsPatchRename({required this.id, required this.name});

  @override
  Map<String, dynamic> toJson() => {
        'rename': {
          'id': id,
          'name': name,
        },
      };
}

class SensorsPatchSetRef extends SensorsPatch {
  final String id;

  const SensorsPatchSetRef({required this.id});

  @override
  Map<String, dynamic> toJson() => {
        'set_ref': {
          'id': id,
        },
      };
}

class SensorsPatchRemove extends SensorsPatch {
  final String id;
  final bool? leave;

  const SensorsPatchRemove({required this.id, this.leave});

  @override
  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{'id': id};
    if (leave != null) payload['leave'] = leave;
    return {'remove': payload};
  }
}

class SensorsPatchPairing extends SensorsPatch {
  final Map<String, dynamic> payload;

  const SensorsPatchPairing({required this.payload});

  @override
  Map<String, dynamic> toJson() => {'pairing': payload};
}

class SensorSnapshot {
  final SensorMeta meta;
  final ClimateSensorTelemetry? telemetry;

  const SensorSnapshot({required this.meta, required this.telemetry});

  String get id => meta.id;
  String get name => meta.name;
  bool get ref => meta.ref;
  String get transport => meta.transport;
  bool get removable => meta.removable;
  String get kind => meta.kind;

  bool get tempValid => telemetry?.tempValid ?? false;
  bool get tempStale => telemetry?.tempStale ?? false;
  bool get humidityValid => telemetry?.humidityValid ?? false;
  double? get temp => telemetry?.temp;
  double? get humidity => telemetry?.humidity;
}
