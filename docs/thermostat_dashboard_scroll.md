# Thermostat Dashboard And Live Metrics Architecture

## Ownership

- `HomePage` owns the root `Scaffold`, drawer, MQTT activity indicator, and
  settings navigation.
- A `DevicePresenter` declares whether it embeds the app bar. The thermostat
  presenter does; fallback, offline, and compatibility states keep the regular
  `HomePage` app bar.
- `DevicePresenterChrome` passes the root navigation callbacks and activity
  indicator into an embedded presenter without coupling presenter tests to the
  global session BLoCs.

## Thermostat dashboard

The dashboard keeps one vertical scroll owner, but it has no content scroll
range:

1. Pinned `ThermostatDashboardAppBar` / `SliverAppBar`.
2. `SliverFillRemaining` for the adaptive temperature carousel and
   horizontal heating-status layout.

The mode bar is fixed above the bottom safe area. The remaining
`CustomScrollView` exists to preserve pull-to-refresh and to expose positive
overscroll to the live-values surface.

## Live values

- `ThermostatDashboardSchema.tiles` remains the only source of tile visibility
  and order.
- `ThermostatLiveMetricsOverlay` maps upward dashboard overscroll to a
  `DraggableScrollableSheet` and owns settling, Back, focus, reduced motion,
  scrim, and analytics.
- `ThermostatLiveMetricsSheet` renders the existing tile widgets in one adaptive
  grid. Tile MQTT bindings and history routes are unchanged.
- When there are no supported tiles, the overscroll behavior and its one-time
  gesture coach are not installed.
- When live tiles exist, an app-level guide teaches the upward gesture once per
  installation. The permanent handle is omitted to keep the dashboard quiet.

## Responsive layout

- Portrait divides the available `SliverFillRemaining` height between the
  carousel and compact horizontal `ON` / `OFF` status.
- Wide landscape puts those sections side by side.
- The history preview is enabled only when the carousel has at least 330 logical
  pixels. Below 220 pixels, or with very large text, the temperature card hides
  secondary schedule lines and uses its ultra-compact presentation.
- Large text changes the live grid to one column.

The temperature carousel keeps incoming sensor order and moves page state to
the reference sensor. A vertical card drag no longer opens history; only the
44-pixel chart action does.

## Regression checks

- `thermostat_presenters_test.dart` covers zero dashboard scroll extent,
  responsive layout, config order, and tile history navigation.
- `thermostat_live_metrics_overlay_test.dart` covers drag thresholds, Back,
  close gestures, reduced motion, and pull-to-refresh propagation.
- `temperature_minimal_panel_test.dart` remains the source for carousel order,
  late reference metadata, horizontal paging, history action, and
  stale-temperature behavior.
- `heating_status_horizontal_card_test.dart` covers explicit status text,
  semantics, tap behavior, and reduced motion.
