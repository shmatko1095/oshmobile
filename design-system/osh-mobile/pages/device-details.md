# Device Details Page Overrides

Use `MASTER.md` as the base. This file describes the current device-details implementation.

## Layout

- Thermostat dashboards use a `Stack` with one `CustomScrollView` and a fixed
  bottom control layer.
- The scroll content contains:
  - a normal pinned `SliverAppBar` with the room/device name;
  - the temperature carousel;
  - the full-width configuration-driven heating `ON` / `OFF` card.
- `ThermostatModeBar` is positioned above the bottom safe area and never scrolls
  with the dashboard. The scroll content reserves the complete panel and hint
  height so the final tile cannot be obscured.
- The temperature carousel keeps the 30% larger visual target on regular phones.
  Its height is capped from the real viewport constraints on compact and
  landscape layouts.
- Offline, compatibility, and unknown-layout states continue to use their
  separate centered card-based screens.

## Card System

- Device details intentionally use more visible card framing than settings/home.
- Shared detail tiles are built from `AppSolidCard` and `AppGlassCard`.
- `heatingToggle` drives both the horizontal dashboard status and the square
  live-value tile. The explicit `ON` / `OFF` text is the primary state signal;
  color and the Material icon are secondary cues. When heating is active, both
  cards use the same warm filled-card language. The wide dashboard card uses an
  even tonal fill and a centered halo instead of a directional hotspot. It keeps
  a compact 96 dp base height so the temperature carousel remains dominant.
- `loadFactor24h` and `energyUsed` are separate live-value tiles, ordered after
  `heatingToggle`. Their values are rolling 24-hour backend summaries rather
  than client-side MQTT aggregations. Insufficient coverage uses the unavailable
  state `—`; it must never be styled or announced as a real zero. The combined
  `dailyStats24h` widget is unsupported.
- The hero temperature card remains the strongest visual element on the control
  screen and contains no heating flame indicator.
- Energy and heating usage history uses vertical columns from zero. Bucket
  width adapts to the selected range, while unavailable buckets keep their
  horizontal position as visible gaps. Do not connect gaps, interpolate them,
  or draw zero-height data bars. Tooltips are available only for populated
  columns; reduced-motion mode removes the chart transition.

## Interaction

- Horizontal drags remain owned by the sensor `PageView`.
- Temperature history opens only from the 44 dp chart action on the selected
  sensor card; vertical card drags do not navigate.
- Both heating status cards open the same heating-history route.
- The route enters with a short bottom slide plus fade. Respect
  `MediaQuery.disableAnimations` by using a zero-duration transition.
- The one-time mode editing hint is rendered above the fixed mode bar.
- Host page pull-to-refresh and optimistic mode switching remain supported.

## Configuration

- History entry points are visible only when `integrations.history.views`
  contains at least one supported graph series.
- Unknown or unsupported history entries do not break the thermostat dashboard.
- Dashboard and live-value visibility still come from
  `integrations.oshmobile.widgets`; unknown widget IDs are ignored.
