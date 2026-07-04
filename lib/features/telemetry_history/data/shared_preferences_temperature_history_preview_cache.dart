import 'dart:convert';

import 'package:oshmobile/features/telemetry_history/domain/contracts/temperature_history_preview_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesTemperatureHistoryPreviewCache
    implements TemperatureHistoryPreviewCache {
  SharedPreferencesTemperatureHistoryPreviewCache(this._prefs);

  static const String _keyPrefix = 'temperature_history_preview.v1';
  static const int _schemaVersion = 1;

  final SharedPreferences _prefs;

  @override
  Future<TemperatureHistoryPreviewCacheRecord?> read({
    required String namespace,
    required String seriesKey,
    required DateTime nowUtc,
    required Duration maxAge,
  }) async {
    final key = _cacheKey(namespace: namespace, seriesKey: seriesKey);
    final raw = _prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await _prefs.remove(key);
        return null;
      }

      final map = decoded.cast<String, dynamic>();
      if (map['schema'] != _schemaVersion) {
        await _prefs.remove(key);
        return null;
      }

      final savedAt = _parseDateTime(map['savedAt']);
      if (savedAt == null || nowUtc.difference(savedAt.toUtc()) > maxAge) {
        await _prefs.remove(key);
        return null;
      }

      final values = _parseValues(map['values']);
      final timestamps = _parseTimestamps(map['timestamps']);
      if (values == null ||
          timestamps == null ||
          values.isEmpty ||
          values.length != timestamps.length) {
        await _prefs.remove(key);
        return null;
      }

      return TemperatureHistoryPreviewCacheRecord(
        values: values,
        timestamps: timestamps,
        savedAt: savedAt.toUtc(),
        windowStart: _parseDateTime(map['windowStart'])?.toUtc(),
        windowEnd: _parseDateTime(map['windowEnd'])?.toUtc(),
      );
    } catch (_) {
      await _prefs.remove(key);
      return null;
    }
  }

  @override
  Future<void> write({
    required String namespace,
    required String seriesKey,
    required TemperatureHistoryPreviewCacheRecord record,
  }) {
    if (record.values.isEmpty ||
        record.values.length != record.timestamps.length) {
      return remove(namespace: namespace, seriesKey: seriesKey);
    }

    return _prefs.setString(
      _cacheKey(namespace: namespace, seriesKey: seriesKey),
      jsonEncode(
        <String, dynamic>{
          'schema': _schemaVersion,
          'savedAt': record.savedAt.toUtc().toIso8601String(),
          'windowStart': record.windowStart?.toUtc().toIso8601String(),
          'windowEnd': record.windowEnd?.toUtc().toIso8601String(),
          'values': record.values,
          'timestamps': [
            for (final timestamp in record.timestamps)
              timestamp.toUtc().toIso8601String(),
          ],
        },
      ),
    );
  }

  @override
  Future<void> remove({
    required String namespace,
    required String seriesKey,
  }) {
    return _prefs.remove(_cacheKey(namespace: namespace, seriesKey: seriesKey));
  }

  String _cacheKey({
    required String namespace,
    required String seriesKey,
  }) {
    return '$_keyPrefix.${Uri.encodeComponent(namespace)}.'
        '${Uri.encodeComponent(seriesKey)}';
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  List<double>? _parseValues(dynamic raw) {
    if (raw is! List) return null;
    final values = <double>[];
    for (final value in raw) {
      final parsed = value is num ? value.toDouble() : null;
      if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
      values.add(parsed);
    }
    return values;
  }

  List<DateTime>? _parseTimestamps(dynamic raw) {
    if (raw is! List) return null;
    final timestamps = <DateTime>[];
    for (final value in raw) {
      final parsed = _parseDateTime(value)?.toUtc();
      if (parsed == null) return null;
      timestamps.add(parsed);
    }
    return timestamps;
  }
}
