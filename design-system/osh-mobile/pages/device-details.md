# Device Details Page Overrides

Use `MASTER.md` as base. This file defines only device-details-specific adjustments.

## Layout

- Keep hero temperature panel + mode bar + 2-column telemetry grid.
- Preserve current information hierarchy and interactions.

## Card System

- Tile cards should visually read as One UI dark surfaces.
- Avoid bright blue backgrounds and avoid hard outer frames.
- Keep shared card wrapper usage; tokenize radius/padding/border alpha.

## Data Typography

- Metrics use shared metric tokens (`metricLarge`, `metricXL`).
- Labels use `caption` / `bodyStrong` consistently.

## Interaction

- Preserve current taps, mode switching, and state transitions.
- Keep consistent motion durations from global motion tokens.

## Keep As-Is

- Existing thermostat logic and capability binding.
- Existing tile composition and ordering.
