import 'json_utils.dart';

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
    const allowed = {'enabled', 'transport', 'timeout_sec', 'started_ts'};
    const required = {'enabled', 'transport', 'timeout_sec', 'started_ts'};

    if (!hasOnlyKeys(json, allowed) || !hasRequiredKeys(json, required)) return null;

    final enabled = asBool(json['enabled']);
    final transport = asString(json['transport']);
    final timeoutSec = asInt(json['timeout_sec']);
    final startedTs = asInt(json['started_ts']);

    if (enabled == null || transport == null || timeoutSec == null || startedTs == null) {
      return null;
    }

    if (timeoutSec < 0 || startedTs < 0) return null;

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
    const allowed = {'id', 'name', 'ref', 'transport', 'removable', 'kind'};
    const required = {'id', 'name', 'ref', 'transport', 'removable', 'kind'};

    if (!hasOnlyKeys(json, allowed) || !hasRequiredKeys(json, required)) return null;

    final id = asString(json['id']);
    final name = asString(json['name']);
    final ref = asBool(json['ref']);
    final transport = asString(json['transport']);
    final removable = asBool(json['removable']);
    final kind = asString(json['kind']);

    if (id == null || name == null || ref == null || transport == null || removable == null || kind == null) {
      return null;
    }

    if (!validStringLength(id, min: 1, max: 31)) return null;
    if (!validStringLength(name, max: 31)) return null;

    const kinds = {'air', 'floor', 'generic'};
    if (!kinds.contains(kind)) return null;

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
    const allowed = {'pairing', 'items'};
    const required = {'pairing', 'items'};

    if (!hasOnlyKeys(json, allowed) || !hasRequiredKeys(json, required)) return null;

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
    const allowed = {'id', 'name', 'ref'};
    const required = {'id', 'name', 'ref'};
    if (!hasOnlyKeys(json, allowed) || !hasRequiredKeys(json, required)) return null;

    final id = asString(json['id']);
    final name = asString(json['name']);
    final ref = asBool(json['ref']);
    if (id == null || name == null || ref == null) return null;

    if (!validStringLength(id, min: 1, max: 31)) return null;
    if (!validStringLength(name, max: 31)) return null;

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
  bool get humidityValid => telemetry?.humidityValid ?? false;
  double? get temp => telemetry?.temp;
  double? get humidity => telemetry?.humidity;
}

class ClimateSensorTelemetry {
  final String id;
  final bool tempValid;
  final bool humidityValid;
  final double? temp;
  final double? humidity;

  const ClimateSensorTelemetry({
    required this.id,
    required this.tempValid,
    required this.humidityValid,
    required this.temp,
    required this.humidity,
  });

  static ClimateSensorTelemetry? fromJson(Map<String, dynamic> json) {
    const allowed = {'id', 'temp_valid', 'humidity_valid', 'temp', 'humidity'};
    const required = {'id', 'temp_valid', 'humidity_valid'};

    if (!hasOnlyKeys(json, allowed) || !hasRequiredKeys(json, required)) return null;

    final id = asString(json['id']);
    final tempValid = asBool(json['temp_valid']);
    final humidityValid = asBool(json['humidity_valid']);

    if (id == null || tempValid == null || humidityValid == null) return null;
    if (!validStringLength(id, min: 1, max: 31)) return null;

    final tempRaw = json['temp'];
    final humidityRaw = json['humidity'];

    final temp = tempRaw == null ? null : asNum(tempRaw)?.toDouble();
    final humidity = humidityRaw == null ? null : asNum(humidityRaw)?.toDouble();

    if (tempValid && temp == null) return null;
    if (humidityValid && humidity == null) return null;

    return ClimateSensorTelemetry(
      id: id,
      tempValid: tempValid,
      humidityValid: humidityValid,
      temp: temp,
      humidity: humidity,
    );
  }
}

class TelemetryState {
  final List<ClimateSensorTelemetry> climateSensors;
  final bool heaterEnabled;
  final int loadFactor;

  const TelemetryState({
    required this.climateSensors,
    required this.heaterEnabled,
    required this.loadFactor,
  });

  static TelemetryState? fromJson(Map<String, dynamic> json) {
    const allowed = {'climate_sensors', 'heater_enabled', 'load_factor'};
    const required = {'climate_sensors', 'heater_enabled', 'load_factor'};

    if (!hasOnlyKeys(json, allowed) || !hasRequiredKeys(json, required)) return null;

    final sensorsRaw = json['climate_sensors'];
    final heaterEnabled = asBool(json['heater_enabled']);
    final loadFactor = asInt(json['load_factor']);

    if (sensorsRaw is! List || heaterEnabled == null || loadFactor == null) return null;

    final sensors = <ClimateSensorTelemetry>[];
    for (final item in sensorsRaw) {
      if (item is! Map) return null;
      final parsed = ClimateSensorTelemetry.fromJson(item.cast<String, dynamic>());
      if (parsed == null) return null;
      sensors.add(parsed);
    }

    return TelemetryState(
      climateSensors: sensors,
      heaterEnabled: heaterEnabled,
      loadFactor: loadFactor,
    );
  }
}
