bool? parseThermostatHeatingState(dynamic value) {
  if (value is bool) return value;

  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
    return null;
  }

  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
        return true;
      case 'false':
      case '0':
        return false;
    }
  }

  return null;
}
