import 'dart:convert';

/// Typed model for alias: "telemetry"
class Telemetry {
  final int largestFreeBlock;
  final int minFreeHeap;
  final int freeHeapSize;
  final double chipTemp;
  final Map<String, int> systemStat; // dynamic keys: task -> stack/usage/etc.
  final String runTimeStat; // e.g. "disabled" | "enabled"

  const Telemetry({
    required this.largestFreeBlock,
    required this.minFreeHeap,
    required this.freeHeapSize,
    required this.chipTemp,
    required this.systemStat,
    required this.runTimeStat,
  });

  /// Alias name you can use for Signal<Telemetry>('telemetry')
  static const alias = 'telemetry';

  Telemetry copyWith({
    int? largestFreeBlock,
    int? minFreeHeap,
    int? freeHeapSize,
    double? chipTemp,
    Map<String, int>? systemStat,
    String? runTimeStat,
  }) {
    return Telemetry(
      largestFreeBlock: largestFreeBlock ?? this.largestFreeBlock,
      minFreeHeap: minFreeHeap ?? this.minFreeHeap,
      freeHeapSize: freeHeapSize ?? this.freeHeapSize,
      chipTemp: chipTemp ?? this.chipTemp,
      systemStat: systemStat ?? this.systemStat,
      runTimeStat: runTimeStat ?? this.runTimeStat,
    );
  }

  // ---------- JSON parsing ----------

  factory Telemetry.fromJson(Map<String, dynamic> json) {
    return Telemetry(
      largestFreeBlock: _asInt(json['largestFreeBlock']),
      minFreeHeap: _asInt(json['minFreeHeap']),
      freeHeapSize: _asInt(json['freeHeapSize']),
      chipTemp: _asDouble(json['chipTemp']),
      systemStat: _asStringIntMap(json['systemStat']),
      runTimeStat: (json['runTimeStat'] ?? '').toString(),
    );
  }

  /// Tolerant constructor from any dynamic payload:
  /// - already-typed Telemetry -> return as-is
  /// - Map -> fromJson
  /// - String(JSON) -> decode then fromJson
  static Telemetry? maybeFrom(dynamic raw) {
    if (raw == null) return null;
    if (raw is Telemetry) return raw;
    if (raw is Map<String, dynamic>) return Telemetry.fromJson(raw);
    if (raw is Map) {
      return Telemetry.fromJson(raw.cast<String, dynamic>());
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return Telemetry.fromJson(decoded);
        }
        if (decoded is Map) {
          return Telemetry.fromJson(decoded.cast<String, dynamic>());
        }
      } catch (_) {
        /* ignore */
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'largestFreeBlock': largestFreeBlock,
        'minFreeHeap': minFreeHeap,
        'freeHeapSize': freeHeapSize,
        'chipTemp': chipTemp,
        'systemStat': systemStat,
        'runTimeStat': runTimeStat,
      };

  // ---------- helpers ----------

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static Map<String, int> _asStringIntMap(dynamic v) {
    if (v is Map<String, int>) return v;
    if (v is Map) {
      final m = <String, int>{};
      v.forEach((k, val) {
        final ks = k.toString();
        m[ks] = _asInt(val);
      });
      return m;
    }
    return const <String, int>{};
  }
}
