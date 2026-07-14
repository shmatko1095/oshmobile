# Temperature-history overlays

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
