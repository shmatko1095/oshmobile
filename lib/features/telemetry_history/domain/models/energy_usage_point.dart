class EnergyUsagePoint {
  const EnergyUsagePoint({
    required this.from,
    required this.to,
    required this.energyKwh,
    required this.coverageRatio,
  });

  final DateTime from;
  final DateTime to;
  final double? energyKwh;
  final double coverageRatio;
}
