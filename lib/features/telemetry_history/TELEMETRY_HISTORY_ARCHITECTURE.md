# Temperature-history overlays

## Configuration-driven dashboard

`ModelConfiguration.history` parses `integrations.history.series` and ordered
`views`. Only series IDs referenced by `views` become visual metrics. Numeric
series not present in a view remain available to backend ingestion and dashboard
aggregates but are intentionally absent from the history page.

`buildTelemetryHistoryDashboardDefinition` expands
`climate_sensors.*.temp` against the stabilized runtime sensor list, then adds
the remaining supported numeric series in view order. Target and heater series
become overlays instead of standalone plots. Unknown references and unsupported
value types are skipped.

Hosts enter the feature through `TelemetryHistoryNavigator`. Its
`prepareDashboardFromHost` method builds this definition once and returns a
nullable callback: `null` means that no configured metric is actually
renderable for the supplied runtime sensors. `openDashboardFromHost` remains a
compatibility wrapper. Host features therefore do not import the internal
definition builder or history-page navigator implementation.

The page loads all rendered metrics into independent keyed states and presents
them in one `CustomScrollView`. Temperature metrics are grouped into one nested
horizontal carousel with one sensor per page; the initial sensor series selects
the starting page. Non-temperature metrics remain independent vertical
sections, and configuration order is preserved at the temperature group's first
position. Domain models `TelemetryHistoryRange` and `TelemetryHistoryWindow`
own local calendar boundaries; the cubit
converts them to UTC only when it invokes the history API. Changing a calendar
period increments the request scope, discards the previous window data, and
prevents late responses from overwriting the new state.

`TelemetryHistoryRetentionPolicy` is the single domain owner of the 370-day
query limit, earliest available local day, real UTC-duration validation for a
custom window, and permission to enter the previous preset period. Both the
cubit and calendar sheet receive the same policy, so presentation widgets do
not import cubit constants or duplicate retention rules.

The app toolbar and period controls are separate pinned slivers. A
`PinnedHeaderSliver` measures the period controls from their current content,
while `AnimatedSize` transitions between the full preset controls and the
compact custom-range row without reserving empty toolbar space. The period
header supports the four calendar presets plus a custom date range. The custom
picker stores an inclusive local end date as the next local midnight
internally, clips the current day at `now`, and validates the actual UTC query
duration against the policy's mobile API limit so DST transitions do not create
an oversized request. Entering custom mode remembers the exact preset window;
clearing it restores that window and reloads the same configured series. The
calendar is presentation-only: it does not change history config or the backend
wire format.

Preset navigation is bounded by the same 370-day archive window used by the
custom picker. The previous arrow is disabled when the preceding calendar
period would be entirely outside that archive. History requests continue to
use `auto` resolution: the backend may return an older day or week from a
coarser retained rollup. The mobile UI renders those retained samples without a
resolution badge because the aggregation level is a storage detail rather than
a separate user action. Empty data therefore means the selected archive window
truly has no retained samples.

The temperature-history screen loads a reference sensor's temperature,
`heater_enabled`, and a separate atomic thermostat-setpoint projection. The
setpoint reader first calls
`/v1/mobile/devices/{serial}/telemetry/history/setpoint`. It falls back to the
legacy `target_temp,setpoint_on,setpoint_off` generic-series request only when
the typed endpoint explicitly returns `404` or `501`. Authentication, network,
server, and malformed-payload failures are surfaced unchanged.

The typed domain state is exactly one of `temperature`, `on`, `off`, or
`inactive` per `bucket_start`. The legacy adapter joins values only when their
bucket timestamps are exactly equal and drops ambiguous combinations; it never
chooses an arbitrary priority between temperature, ON, and OFF.

The atomic projection is rendered as one step-line through the `Target`
selector:

- `temperature` uses its real Celsius value;
- `ON` uses plot placement `41.0`, one degree above the current maximum
  configurable temperature setpoint of `40.0`;
- `OFF` is rendered as a line two percent above the bottom of the temperature
  chart and is excluded from its Y-axis range;
- `inactive` creates a gap;
- the tooltip renders one `Target` row with `ON`, `OFF`, or the temperature,
  never the marker values `41.0` or `0.0`.

Do not map ON/OFF to the temperature axis as `1` and `0`: that would compress
the sensor-temperature range. `heater_enabled` remains a separate activity
band and is not a schedule-setpoint indicator.

## Canonical tooltip bucket

`HistoryMultiLinePoint` keeps each plot placement, display value, range, and
tooltip text together with its timestamp. The touched point from the primary
temperature line is the tooltip anchor. Overlay rows are admitted only when
their timestamp is exactly the same `bucket_start`; nearby pixels or adjacent
buckets are never merged. This guarantees a single understandable target state
even when several setpoint transitions happened inside a backend rollup window.

## Chart animation identity

`fl_chart` interpolates line bars by their list index, rather than by the
application-level series ID. `HistoryMultiLineChart` therefore keys its inner
`LineChart` by the ordered IDs of the visible series. A topology change, such
as enabling or disabling the heating band, creates a fresh chart instead of
animating one metric into another. A data-only update keeps that key unchanged
and retains the normal chart animation.
