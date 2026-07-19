# Thermostat dashboard architecture

The thermostat presenter separates frequent controls from diagnostic values.

- The dashboard renders the room AppBar, temperature sensor carousel, the
  horizontal heating status, and the fixed mode bar.
- When a renderable `heatingToggle` is present, the schema promotes its bind to
  `ThermostatDashboardSchema.heatingStatus`. The dashboard uses that bind for a
  full-width `ON` / `OFF` status card while the original square status tile
  remains in the live-values surface. Both cards share the warm active fill and
  glow language; the wide card uses a uniform tonal surface with a centered halo
  to avoid a directional hotspot. Both entry points open heating history. The
  horizontal card uses a compact 96 dp base height.
  Missing and unreadable configurations do not produce the promoted status.
- Temperature cards intentionally contain no device-level heating indicator;
  they remain focused on the selected sensor, schedule target, and history.
- In portrait, the temperature carousel viewport is full-bleed. The selected
  card uses 85% of that viewport, while adjacent cards remain visible and are
  clipped only by the physical screen edges. The page dots reinforce swipe
  discoverability. The heating status and mode bar keep their 20 dp horizontal
  inset. Landscape keeps the inset around the side-by-side carousel and status
  layout.
- The portrait hero switches to its ultra-compact content below 300 dp so the
  full-width page remains overflow-safe on short screens.
- The dashboard `CustomScrollView` has no content scroll range. Its positive
  overscroll drives the live-values surface; negative overscroll continues to
  reach the host `RefreshIndicator`.
- `ThermostatDashboardSchema.tiles` is the only source for the live-values
  surface composition and order. Unknown widget IDs are filtered by the schema
  builder before presentation.
- Daily energy and 24-hour heating runtime are independent live-value tiles.
  Both request rolling `[now - 24h, now)` summaries from the dedicated backend
  usage endpoints with the shared `AppPollingIntervals.deviceData` cadence.
  They never aggregate MQTT samples in the presenter. A backend value made
  unavailable by insufficient coverage is shown as `—`, not as zero. The
  removed `dailyStats24h` widget ID is not recognized as a compatibility
  surface.
- `loadFactor24h` is backend-backed and remains renderable with empty
  `control_ids`; it no longer depends on a readable `load_factor` control.
  `energyUsed` follows the same backend-summary path. `heatingToggle` remains
  the live `heaterEnabled` control used by both ON/OFF cards.
- Live `telemetry@1` decoding is field-tolerant. The runtime JSON Schema remains
  the strict compatibility diagnostic, while `RuntimeJsonSchemaSanitizer`
  recursively removes only invalid known fields before `TelemetryState` is
  built. Unknown fields are retained for forward compatibility. A malformed
  scalar therefore makes only its bound control unavailable; a malformed array
  item is skipped without hiding valid siblings. A climate sensor without a
  usable `id` is the smallest unit that must be dropped because it cannot be
  joined with sensor metadata.
- `TelemetryState` contains nullable live fields and does not expose the
  deprecated firmware `load_factor`. Both current payloads without that field
  and legacy payloads that still include it are accepted. Schema and field
  issues are logged once per unique path/reason during a device repository
  lifetime; raw MQTT payloads are never included in these diagnostics.
- Both usage tiles open their dedicated column-chart history. Existing generic
  control tiles continue to reuse their MQTT bindings and generic history
  navigation inside `ThermostatLiveMetricsSheet`.
- Temperature-card vertical drags do not navigate. Detailed temperature history
  is opened only from the chart action on the active sensor card.

The production geometry is calculated by the classless pure helper
`resolveThermostatDashboardLayout`. It contains the existing presenter formulas
for carousel, summary status, mode-bar, hint, and compact/landscape allocation; widget
tests verify the resulting rendered geometry instead of testing a duplicate
legacy hero-height formula.

`ThermostatLiveMetricsOverlay` owns sheet extent, dashboard overscroll, Back,
focus restoration, reduced motion, and screen analytics. The visual sheet is a
separate widget and uses the `DraggableScrollableSheet` scroll controller for
both sheet dragging and the config-driven grid.

The live-values surface intentionally has no permanent handle. A versioned
app-level user-guide coach teaches the upward gesture once per installation
when the selected thermostat configuration contains supported live tiles.
Thermostat-specific guide integration is owned by
`devices/details/presentation/user_guide`; the common `user_guide` feature is
used only through its public cubit, topic, registry, modal, and spotlight APIs.
The dashboard registers its contextual host only while an eligible thermostat
is mounted. The active page is retained when a real live sheet, mode editor, or
temperature editor is opened and then closed.

History navigation crosses the feature boundary only through
`ThermostatTelemetryHistoryOpener`. Its `prepareDashboard` method asks the public
telemetry-history facade to build the config-driven definition once and returns
a nullable action. Runtime sensors participate in that preparation: a
temperature-only configuration has no dead history action until a sensor is
available, while numeric views remain available without temperature sensors.
The active sensor card prepares the same dashboard with its sensor anchor.

When preparation succeeds, the live surface pins a lightweight `Show history`
action above the bottom safe area. It opens the same prepared dashboard used by
the temperature-card chart action. The live sheet stays open underneath the
history route, so Back returns to its previous scroll position. Configurations
without a renderable definition do not render the action. Legacy tile-specific
history methods remain compatibility wrappers on the adapter.
