class TemperatureSensorData {
  const TemperatureSensorData({
    required this.id,
    required this.name,
    required this.kind,
    required this.isReference,
    required this.tempValid,
    required this.humidityValid,
    required this.temp,
    required this.humidity,
  });

  final String id;
  final String name;
  final String? kind;
  final bool isReference;
  final bool tempValid;
  final bool humidityValid;
  final double? temp;
  final double? humidity;
}

class TemperatureSensorsResolver {
  final List<String> _sensorOrder = <String>[];

  List<TemperatureSensorData> resolve(dynamic raw) {
    if (raw is! List) {
      _sensorOrder.clear();
      return const <TemperatureSensorData>[];
    }

    final parsed = <TemperatureSensorData>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final id = (map['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;

      final nameRaw = (map['name'] ?? '').toString().trim();
      final name = nameRaw.isEmpty ? id : nameRaw;

      final tempRaw = _asNum(map['temp']);
      final humidityRaw = _asNum(map['humidity']);
      final tempValid = _asBool(map['temp_valid']) && tempRaw != null;
      final humidityValid =
          _asBool(map['humidity_valid']) && humidityRaw != null;

      parsed.add(
        TemperatureSensorData(
          id: id,
          name: name,
          kind: map['kind']?.toString(),
          isReference: _asBool(map['ref']),
          tempValid: tempValid,
          humidityValid: humidityValid,
          temp: tempValid ? tempRaw.toDouble() : null,
          humidity: humidityValid ? humidityRaw.toDouble() : null,
        ),
      );
    }

    if (parsed.isEmpty) {
      _sensorOrder.clear();
      return const <TemperatureSensorData>[];
    }

    final incomingIds = parsed.map((sensor) => sensor.id).toSet();
    _sensorOrder.removeWhere((id) => !incomingIds.contains(id));

    final knownIds = _sensorOrder.toSet();
    for (final sensor in parsed) {
      if (!knownIds.contains(sensor.id)) {
        _sensorOrder.add(sensor.id);
        knownIds.add(sensor.id);
      }
    }

    final byId = <String, TemperatureSensorData>{
      for (final sensor in parsed) sensor.id: sensor,
    };

    return _sensorOrder
        .map((id) => byId[id])
        .whereType<TemperatureSensorData>()
        .toList(growable: false);
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}
