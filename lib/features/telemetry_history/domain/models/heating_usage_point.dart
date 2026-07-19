class HeatingUsagePoint {
  const HeatingUsagePoint({
    required this.from,
    required this.to,
    required this.loadFactorPercent,
    required this.coverageRatio,
  });

  final DateTime from;
  final DateTime to;
  final double? loadFactorPercent;
  final double coverageRatio;
}
