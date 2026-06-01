# Telemetry History Page Overrides

Use `MASTER.md` as the base. This file describes the lightweight history refresh target for the current Flutter implementation.

## Visual Direction

- Keep the app dark-first and operational, but make history screens more data-first than card-first.
- Prefer a hybrid dark treatment: black canvas, soft chart plane, muted axes, and restrained accent colors.
- Do not copy blue full-screen reference gradients literally; use the reference for air, hierarchy, and chart prominence.

## Chart Treatment

- Time-series charts keep straight line segments to avoid implying smoothed sensor data.
- Energy delta stays a bar chart because `power_meter.energy_wh_delta` is interval energy, not a continuous state.
- Axes should be readable but quiet:
  - no vertical grid by default,
  - very subtle horizontal grid,
  - lighter axis borders and muted tick labels.
- Chart fills and bar gradients should support depth without becoming the dominant visual element.

## Layout

- Metric selector chips are compact, horizontally scrollable, and keep safe touch targets.
- Summary stats should read as lightweight metadata, not as a heavy card group; avoid strong vertical separators.
- The range selector remains bottom-positioned and touch-friendly, with lower visual weight than primary dashboard controls.

## Interaction

- Preserve current paging, metric selection, range switching, tooltips, and loading/error/empty states.
- Keep existing accessibility semantics for summary values and chart labels.
