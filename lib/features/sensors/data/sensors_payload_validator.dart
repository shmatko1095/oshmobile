import 'package:oshmobile/core/network/mqtt/protocol/v1/json_utils.dart';

bool validateSensorsSetPayload(Map<String, dynamic> data) {
  const allowedTop = {'items'};
  if (!hasOnlyKeys(data, allowedTop) || !hasRequiredKeys(data, allowedTop))
    return false;

  final itemsRaw = data['items'];
  if (itemsRaw is! List) return false;

  for (final item in itemsRaw) {
    if (item is! Map) return false;
    final m = item.cast<String, dynamic>();
    const allowed = {'id', 'name', 'ref'};
    const required = {'id', 'name', 'ref'};
    if (!hasOnlyKeys(m, allowed) || !hasRequiredKeys(m, required)) return false;

    final id = asString(m['id']);
    final name = asString(m['name']);
    final ref = asBool(m['ref']);
    if (id == null || name == null || ref == null) return false;
    if (!validStringLength(id, min: 1, max: 31)) return false;
    if (!validStringLength(name, max: 31)) return false;
  }

  return true;
}

bool validateSensorsPatchPayload(Map<String, dynamic> data) {
  const allowedTop = {
    'rename',
    'set_ref',
    'set_temp_calibration',
    'remove',
    'pairing'
  };
  if (!hasOnlyKeys(data, allowedTop)) return false;

  int present = 0;
  for (final key in allowedTop) {
    if (data.containsKey(key)) present++;
  }
  if (present != 1) return false;

  if (data.containsKey('rename')) {
    final raw = data['rename'];
    if (raw is! Map) return false;
    final m = raw.cast<String, dynamic>();
    const allowed = {'id', 'name'};
    const required = {'id', 'name'};
    if (!hasOnlyKeys(m, allowed) || !hasRequiredKeys(m, required)) return false;
    final id = asString(m['id']);
    final name = asString(m['name']);
    if (id == null || name == null) return false;
    if (!validStringLength(id, min: 1, max: 31)) return false;
    if (!validStringLength(name, max: 31)) return false;
    return true;
  }

  if (data.containsKey('set_ref')) {
    final raw = data['set_ref'];
    if (raw is! Map) return false;
    final m = raw.cast<String, dynamic>();
    const allowed = {'id'};
    const required = {'id'};
    if (!hasOnlyKeys(m, allowed) || !hasRequiredKeys(m, required)) return false;
    final id = asString(m['id']);
    if (id == null || !validStringLength(id, min: 1, max: 31)) return false;
    return true;
  }

  if (data.containsKey('set_temp_calibration')) {
    final raw = data['set_temp_calibration'];
    if (raw is! Map) return false;
    final m = raw.cast<String, dynamic>();
    const allowed = {'id', 'value'};
    const required = {'id', 'value'};
    if (!hasOnlyKeys(m, allowed) || !hasRequiredKeys(m, required)) return false;

    final id = asString(m['id']);
    final valueRaw = asNum(m['value'])?.toDouble();
    if (id == null || valueRaw == null) return false;
    if (!validStringLength(id, min: 1, max: 31)) return false;
    if (valueRaw < -10 || valueRaw > 10) return false;
    if (!_isMultipleOfHalf(valueRaw)) return false;
    return true;
  }

  if (data.containsKey('remove')) {
    final raw = data['remove'];
    if (raw is! Map) return false;
    final m = raw.cast<String, dynamic>();
    const allowed = {'id', 'leave'};
    const required = {'id'};
    if (!hasOnlyKeys(m, allowed) || !hasRequiredKeys(m, required)) return false;
    final id = asString(m['id']);
    if (id == null || !validStringLength(id, min: 1, max: 31)) return false;
    if (m.containsKey('leave') && m['leave'] is! bool) return false;
    return true;
  }

  if (data.containsKey('pairing')) {
    final raw = data['pairing'];
    if (raw is! Map) return false;
    return true;
  }

  return false;
}

bool _isMultipleOfHalf(double value) {
  final scaled = value * 2;
  return (scaled - scaled.round()).abs() < 1e-9;
}
