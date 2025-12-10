/// Immutable snapshot of device settings as nested JSON.
///
/// Важно: сам SettingsSnapshot иммутабельный, но внутри него
/// мы оперируем обычными (мутабельными) Map-ами для удобного
/// копирования/merge.
class SettingsSnapshot {
  /// Underlying nested JSON map.
  ///
  /// По договорённости не мутируем этот Map снаружи, а используем
  /// copyWithValue/merged/toJson.
  final Map<String, dynamic> raw;

  const SettingsSnapshot._(this.raw);

  /// Create snapshot from JSON (defensively copies the map).
  factory SettingsSnapshot.fromJson(Map<String, dynamic> json) {
    return SettingsSnapshot._(_deepCloneMap(json));
  }

  /// Empty snapshot.
  factory SettingsSnapshot.empty() => const SettingsSnapshot._({});

  /// Get deep JSON copy.
  Map<String, dynamic> toJson() => _deepCloneMap(raw);

  /// Get value by "path", e.g. "display.activeBrightness".
  ///
  /// Returns null if path is missing or type does not match [T].
  T? getValue<T>(String path) {
    final parts = path.split('.');
    dynamic cur = raw;

    for (final part in parts) {
      if (cur is Map<String, dynamic>) {
        if (!cur.containsKey(part)) return null;
        cur = cur[part];
      } else {
        return null;
      }
    }

    if (cur == null) return null;
    if (cur is T) return cur;

    // Mild best-effort coercion for numeric types.
    if (T == int && cur is num) return cur.toInt() as T;
    if (T == double && cur is num) return cur.toDouble() as T;
    if (T == String) return cur.toString() as T;

    return null;
  }

  /// Returns a new snapshot where [path] is set to [value].
  ///
  /// - `path` is dot-separated, e.g. "display.idleTime".
  /// - If intermediate maps are missing – they are created.
  /// - If [value] is null – the key is removed from the target map.
  SettingsSnapshot copyWithValue(String path, Object? value) {
    // Делаем МУТАБЕЛЬНЫЙ клон, без UnmodifiableMapView.
    final copy = _deepCloneMap(raw);
    final parts = path.split('.');
    if (parts.isEmpty) return SettingsSnapshot._(copy);

    Map<String, dynamic> cur = copy;
    for (var i = 0; i < parts.length; i++) {
      final key = parts[i];
      final isLast = i == parts.length - 1;

      if (isLast) {
        if (value == null) {
          cur.remove(key);
        } else {
          cur[key] = value;
        }
      } else {
        final next = cur[key];
        if (next is Map<String, dynamic>) {
          cur = next;
        } else if (next is Map) {
          final normalized = Map<String, dynamic>.from(next.cast<String, dynamic>());
          cur[key] = normalized;
          cur = normalized;
        } else {
          final created = <String, dynamic>{};
          cur[key] = created;
          cur = created;
        }
      }
    }

    return SettingsSnapshot._(copy);
  }

  /// Merge with a JSON "patch" (nested map).
  ///
  /// Values in [patch] override existing values in [raw].
  SettingsSnapshot merged(Map<String, dynamic> patch) {
    // Тоже используем мутируемый клон.
    final base = _deepCloneMap(raw);
    _deepMerge(base, patch);
    return SettingsSnapshot._(base);
  }

  /// Глубокий клон в обычный (изменяемый) Map.
  static Map<String, dynamic> _deepCloneMap(Map<String, dynamic> src) {
    final result = <String, dynamic>{};
    src.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = _deepCloneMap(value);
      } else if (value is Map) {
        result[key] = _deepCloneMap(value.cast<String, dynamic>());
      } else if (value is List) {
        // Список копируем неглубоко — этого достаточно для настроек.
        result[key] = List.of(value);
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  static void _deepMerge(Map<String, dynamic> target, Map<String, dynamic> patch) {
    patch.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final existing = target[key];
        if (existing is Map<String, dynamic>) {
          _deepMerge(existing, value);
        } else {
          target[key] = _deepCloneMap(value);
        }
      } else if (value is Map) {
        final valueMap = value.cast<String, dynamic>();
        final existing = target[key];
        if (existing is Map<String, dynamic>) {
          _deepMerge(existing, valueMap);
        } else {
          target[key] = _deepCloneMap(valueMap);
        }
      } else {
        target[key] = value;
      }
    });
  }
}
