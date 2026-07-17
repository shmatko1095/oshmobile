# Device Details Page Overrides

Use `MASTER.md` as the base. This file describes the current device-details implementation.

## Layout

- Thermostat dashboards use a `Stack` with one `CustomScrollView` and a fixed
  bottom control layer.
- The scroll content contains:
  - a normal pinned `SliverAppBar` with the room/device name;
  - the temperature carousel;
  - the full-width configuration-driven `dailyStats24h` card;
  - any legacy tiles still listed by an older configuration.
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
- The `dailyStats24h` widget groups energy used and heating runtime for the last
  24 hours with an internal divider and no history tap.
- Legacy `energyUsed`, `loadFactor24h`, `heatingToggle`, `powerNow`,
  `voltageNow`, and `currentNow` implementations remain available when an older
  device configuration lists them.
- The hero temperature card remains the strongest visual element on the control
  screen.

## Interaction

- Horizontal drags remain owned by the sensor `PageView`.
- A deliberate upward drag on the current temperature card opens the shared
  history dashboard. It requires about `56 dp` of travel or a clear upward fling;
  weak and diagonal gestures do not navigate.
- The chart action and upward gesture use the same configuration-driven
  navigator and pass the current sensor ID.
- The route enters with a short bottom slide plus fade. Respect
  `MediaQuery.disableAnimations` by using a zero-duration transition.
- The one-time mode editing hint is rendered above the fixed mode bar.
- Host page pull-to-refresh and optimistic mode switching remain supported.

## Configuration

- History entry points are visible only when `integrations.history.views`
  contains at least one supported graph series.
- Unknown or unsupported history entries do not break the thermostat dashboard.
- Dashboard widget visibility still comes from `integrations.oshmobile.widgets`;
  compatibility widgets are not removed from the app.
