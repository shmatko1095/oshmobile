import 'dart:math' as math;

typedef ThermostatDashboardLayout = ({
  double dashboardBodyHeight,
  double bottomReservedHeight,
  double contentHeight,
  double scaledStatsHeight,
});

ThermostatDashboardLayout resolveThermostatDashboardLayout({
  required double viewportHeight,
  required double topInset,
  required double bottomInset,
  required double textScale,
  required bool hasModeBar,
}) {
  final modeBarReservedHeight = hasModeBar ? 96.0 : 0.0;
  final bottomReservedHeight = bottomInset + modeBarReservedHeight + 10.0;
  final dashboardBodyHeight = math.max(
    0.0,
    viewportHeight - 56.0 - topInset,
  );
  final contentHeight = math.max(
    0.0,
    dashboardBodyHeight - bottomReservedHeight - 12.0,
  );
  final scaledStatsHeight = (112.0 + math.max(0.0, textScale - 1.0) * 68.0)
      .clamp(112.0, 180.0)
      .toDouble();

  return (
    dashboardBodyHeight: dashboardBodyHeight,
    bottomReservedHeight: bottomReservedHeight,
    contentHeight: contentHeight,
    scaledStatsHeight: scaledStatsHeight,
  );
}
