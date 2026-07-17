# Telemetry History Page Overrides

Use `MASTER.md` as the base. This file describes the shared thermostat analytics screen.

## Visual Direction

- Use the global near-black canvas (`#0B0C11`) and a single navy analytics surface in dark mode:
  - primary surface `#1D2A3B`;
  - secondary surface `#243247`;
  - borders `#33445D` at reduced opacity;
  - primary text `#F5F7FA` and secondary text `#9AA6B8`.
- The light theme keeps the same hierarchy with adapted light surfaces; never
  force the application into dark mode.
- Temperature, target, and heating use blue (`#4A8CFF`), green (`#34C759`),
  and warm red (`#FF5252`). Electrical charts use distinct blue/orange/cyan
  accents and text legends, so color is never the only identifier.

## Layout

- Use exactly one vertical `CustomScrollView` for every graph allowed by the
  configuration.
- Temperature graphs share one horizontal carousel within that scroll: one
  sensor per page, opened on the sensor selected on the dashboard. Keep a
  compact position indicator and accessible previous/next controls.
- The pinned `SliverAppBar` owns a pinned bottom header containing:
  - `Day / Week / Month / Year`;
  - previous/next calendar navigation and the formatted period label.
- Graph sections share one navy panel and use quiet dividers. Do not add metric
  chips, full-dashboard paging, or a bottom range selector; horizontal paging is
  reserved for the temperature-sensor carousel.
- Each chart has a stable `240–280 dp` plot area. Summary values remain compact
  metadata above the plot.

## Chart Treatment

- Keep straight line segments around `2 dp`; do not smooth telemetry.
- Use a restrained `12–20%` fill, subtle horizontal grid, and no vertical grid.
- Temperature is always visible. Target and heating are independently toggled
  overlays when their series are present in the configured view.
- Heating is an activity band with its own values and must not change the
  temperature Y-axis.
- Axes and tooltips use local time. Min/max/avg and aggregate labels use the
  actual selected calendar window.

## Calendar Model

- Day is local midnight to midnight.
- Week is Monday through Sunday.
- Month and year follow their actual calendar boundaries.
- The current incomplete period is clipped at the current time; the forward
  arrow is disabled there.
- Convert local boundaries to UTC only at the API boundary.
- Changing range opens the current calendar period, preserves scroll position,
  invalidates the old window, and reloads each displayed series once.

## Configuration and Resilience

- `integrations.history.views` is the only source of graph order and visibility.
- Series definitions outside all views remain parsed for ingestion and
  aggregate consumers but are not rendered.
- `climate_sensors.*.temp` expands to the currently available sensor list.
- Unknown view references, series IDs, and value types are ignored safely.
- Loading, empty, error, and retry states belong to each graph; one failure must
  not block the rest of the page.
