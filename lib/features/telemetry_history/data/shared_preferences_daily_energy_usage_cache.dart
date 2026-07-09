import 'dart:convert';

import 'package:oshmobile/features/telemetry_history/domain/contracts/daily_energy_usage_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesDailyEnergyUsageCache implements DailyEnergyUsageCache {
  SharedPreferencesDailyEnergyUsageCache(this._prefs);

  static const String _keyPrefix = 'daily_energy_usage.v1';
  static const int _schemaVersion = 1;

  final SharedPreferences _prefs;

  @override
  Future<DailyEnergyUsageCacheRecord?> read({
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
      final windowStart = _parseDateTime(map['windowStart']);
      final windowEnd = _parseDateTime(map['windowEnd']);
      final energyWh = _parseDouble(map['energyWh']);
      if (savedAt == null ||
          windowStart == null ||
          windowEnd == null ||
          energyWh == null ||
          nowUtc.difference(savedAt.toUtc()) > maxAge) {
        await _prefs.remove(key);
        return null;
      }

      return DailyEnergyUsageCacheRecord(
        energyWh: energyWh,
        savedAt: savedAt.toUtc(),
        windowStart: windowStart.toUtc(),
        windowEnd: windowEnd.toUtc(),
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
    required DailyEnergyUsageCacheRecord record,
  }) {
    return _prefs.setString(
      _cacheKey(namespace: namespace, seriesKey: seriesKey),
      jsonEncode(
        <String, dynamic>{
          'schema': _schemaVersion,
          'savedAt': record.savedAt.toUtc().toIso8601String(),
          'windowStart': record.windowStart.toUtc().toIso8601String(),
          'windowEnd': record.windowEnd.toUtc().toIso8601String(),
          'energyWh': record.energyWh,
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

  double? _parseDouble(dynamic value) {
    final parsed = value is num ? value.toDouble() : null;
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
    return parsed;
  }
}
