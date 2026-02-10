bool validateSettingsSetPayload(Map<String, dynamic> data) {
  const allowedTop = {'display', 'update', 'time'};
  if (!_hasOnlyKeys(data, allowedTop)) return false;

  final displayRaw = data['display'];
  final updateRaw = data['update'];
  final timeRaw = data['time'];
  if (displayRaw is! Map || updateRaw is! Map || timeRaw is! Map) return false;

  return _validateDisplay(displayRaw.cast<String, dynamic>(), requireAll: true) &&
      _validateUpdate(updateRaw.cast<String, dynamic>(), requireAll: true) &&
      _validateTime(timeRaw.cast<String, dynamic>(), requireAll: true);
}

bool validateSettingsPatchPayload(Map<String, dynamic> data) {
  const allowedTop = {'display', 'update', 'time'};
  if (!_hasOnlyKeys(data, allowedTop)) return false;

  final displayRaw = data['display'];
  final updateRaw = data['update'];
  final timeRaw = data['time'];

  if (displayRaw != null) {
    if (displayRaw is! Map) return false;
    if (!_validateDisplay(displayRaw.cast<String, dynamic>(), requireAll: false)) return false;
  }

  if (updateRaw != null) {
    if (updateRaw is! Map) return false;
    if (!_validateUpdate(updateRaw.cast<String, dynamic>(), requireAll: false)) return false;
  }

  if (timeRaw != null) {
    if (timeRaw is! Map) return false;
    if (!_validateTime(timeRaw.cast<String, dynamic>(), requireAll: false)) return false;
  }

  return true;
}

bool _validateDisplay(Map<String, dynamic> data, {required bool requireAll}) {
  const allowed = {'activeBrightness', 'idleBrightness', 'idleTime', 'dimOnIdle', 'language'};
  if (!_hasOnlyKeys(data, allowed)) return false;
  if (requireAll && !_hasRequiredKeys(data, allowed)) return false;

  if (data.containsKey('activeBrightness')) {
    final v = _asIntStrict(data['activeBrightness']);
    if (v == null || v < 0 || v > 255) return false;
  }
  if (data.containsKey('idleBrightness')) {
    final v = _asIntStrict(data['idleBrightness']);
    if (v == null || v < 0 || v > 255) return false;
  }
  if (data.containsKey('idleTime')) {
    final v = _asIntStrict(data['idleTime']);
    if (v == null || v < 0 || v > 0xFFFFFFFF) return false;
  }
  if (data.containsKey('dimOnIdle')) {
    final v = data['dimOnIdle'];
    if (v is! bool) return false;
  }
  if (data.containsKey('language')) {
    final v = data['language'];
    if (v is! String) return false;
    final ok = RegExp(r'^[a-z0-9_]{2,7}$').hasMatch(v);
    if (!ok) return false;
  }

  return true;
}

bool _validateUpdate(Map<String, dynamic> data, {required bool requireAll}) {
  const allowed = {'autoUpdateEnabled', 'updateAtMidnight', 'checkIntervalMin'};
  if (!_hasOnlyKeys(data, allowed)) return false;
  if (requireAll && !_hasRequiredKeys(data, allowed)) return false;

  if (data.containsKey('autoUpdateEnabled')) {
    final v = data['autoUpdateEnabled'];
    if (v is! bool) return false;
  }
  if (data.containsKey('updateAtMidnight')) {
    final v = data['updateAtMidnight'];
    if (v is! bool) return false;
  }
  if (data.containsKey('checkIntervalMin')) {
    final v = _asIntStrict(data['checkIntervalMin']);
    if (v == null || v < 0 || v > 0xFFFFFFFF) return false;
  }

  return true;
}

bool _validateTime(Map<String, dynamic> data, {required bool requireAll}) {
  const allowed = {'auto', 'timeZone'};
  if (!_hasOnlyKeys(data, allowed)) return false;
  if (requireAll && !_hasRequiredKeys(data, allowed)) return false;

  if (data.containsKey('auto')) {
    final v = data['auto'];
    if (v is! bool) return false;
  }
  if (data.containsKey('timeZone')) {
    final v = _asIntStrict(data['timeZone']);
    if (v == null || v < -128 || v > 127) return false;
  }

  return true;
}

bool _hasOnlyKeys(Map<String, dynamic> map, Set<String> allowed) {
  for (final key in map.keys) {
    if (!allowed.contains(key)) return false;
  }
  return true;
}

bool _hasRequiredKeys(Map<String, dynamic> map, Set<String> required) {
  for (final key in required) {
    if (!map.containsKey(key)) return false;
  }
  return true;
}

int? _asIntStrict(dynamic v) {
  if (v is int) return v;
  if (v is num) {
    if (v % 1 != 0) return null;
    return v.toInt();
  }
  return null;
}
