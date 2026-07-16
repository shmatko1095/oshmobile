# Device session refresh

The device dashboard renders live values from `DeviceSnapshot.controlState`.
`DeviceFacadeImpl` rebuilds that snapshot from the active domain APIs, including
telemetry, schedule, settings, and sensors.

MQTT retained `*.state` messages provide an immediate best-known value, but a
retained schedule snapshot can be older than the device's current schedule
point. While a schedule repository has an active listener, it therefore sends
an immediate `schedule.get` and continues polling at
`AppPollingIntervals.deviceData`. The poll stops when the last listener leaves
the device scope. Poll failures are best-effort because retained updates and
pull-to-refresh remain available.

The thermostat sensor card reads `schedule_current` and `schedule_next` through
configuration bindings. Fresh schedule responses flow through
`DeviceScheduleApiImpl`, `DeviceFacadeImpl`, and `DeviceSnapshotCubit`, so the
card should not own its own timer or fetch logic.
