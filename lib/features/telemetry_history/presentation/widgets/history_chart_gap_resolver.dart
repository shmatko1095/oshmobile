class HistoryChartGapResolver {
  const HistoryChartGapResolver._();

  static const double defaultGapMultiplier = 2.5;

  static double? resolveGapThresholdSeconds(
    List<DateTime?> timestamps, {
    double multiplier = defaultGapMultiplier,
  }) {
    if (timestamps.length < 3 || multiplier <= 0) return null;

    final deltas = <double>[];
    for (var i = 1; i < timestamps.length; i++) {
      final seconds = secondsBetween(timestamps[i - 1], timestamps[i]);
      if (seconds != null && seconds > 0) {
        deltas.add(seconds);
      }
    }

    if (deltas.length < 2) return null;
    deltas.sort();
    final mid = deltas.length ~/ 2;
    final median = deltas.length.isEven
        ? (deltas[mid - 1] + deltas[mid]) / 2
        : deltas[mid];
    if (median <= 0) return null;
    return median * multiplier;
  }

  static double? secondsBetween(DateTime? from, DateTime? to) {
    if (from == null || to == null) return null;
    final deltaMs = to.toUtc().difference(from.toUtc()).inMilliseconds;
    if (deltaMs <= 0) return null;
    return deltaMs / 1000;
  }
}
