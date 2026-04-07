# Device Details Page Overrides

Use `MASTER.md` as the base. This file describes the current device-details implementation.

## Layout

- Keep the current `CustomScrollView` composition:
  - hero temperature panel,
  - mode bar,
  - optional temperature history strip,
  - two-column telemetry grid.
- Offline, compatibility, and unknown-layout states use separate centered card-based screens.

## Card System

- Device details intentionally use more visible card framing than settings/home.
- Shared detail tiles are built from `AppSolidCard` and `AppGlassCard`.
- Common current pattern:
  - `surfaceRaised` or `surfaceAlt` background,
  - subtle white border,
  - accent border or accent glow only for key/active cards.
- Hero temperature panel uses a stronger blue-accent presentation than the rest of the grid.

## Data Typography

- Hero temperature cards use the largest metric sizes in the app (`78` on the main fallback card, `56` on picker-like screens).
- Standard tile metrics land around `20-30` with bold weight.
- Labels typically use secondary/muted colors with semibold weight.
- Mode labels are compact (`12`) and centered.

## Interaction

- Preserve current taps, telemetry drill-ins, and mode switching.
- Mode bar uses optimistic UI:
  - selected mode gets blue fill, blue border, and a short underline,
  - confirmation clears the optimistic state.
- Heating state card uses a warm red/orange gradient and red border when active.
- Host page supports pull-to-refresh.

## Secondary States

- Offline and compatibility flows keep their centered explanatory-card layout.
- These screens currently allow more visible borders, badges, and accent surfaces than the main thermostat dashboard.
- Unsupported/unknown layout pages keep their amber info treatment and metadata cards.

## Keep As-Is

- Existing thermostat logic, capability binding, and tile ordering.
- Existing device-specific presenters and fallback states.
