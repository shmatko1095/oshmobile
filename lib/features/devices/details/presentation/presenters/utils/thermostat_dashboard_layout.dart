import 'dart:math' as math;

typedef ThermostatDashboardLayout = ({
  double dashboardBodyHeight,
  double bottomReservedHeight,
  double contentHeight,
  double scaledSummaryHeight,
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
  final scaledSummaryHeight = (96.0 + math.max(0.0, textScale - 1.0) * 52.0)
      .clamp(96.0, 148.0)
      .toDouble();

  return (
    dashboardBodyHeight: dashboardBodyHeight,
    bottomReservedHeight: bottomReservedHeight,
    contentHeight: contentHeight,
    scaledSummaryHeight: scaledSummaryHeight,
  );
}
