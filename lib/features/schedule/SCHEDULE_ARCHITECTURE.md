# Schedule setpoints

`ScheduleSetpoint` is the typed value used by manual (`mode=on`), daily, and weekly points:

- `temperature` carries a numeric temperature;
- `on` requests heating without a room-temperature target;
- `off` disables heating for the active point.

The repository negotiates behavior from the runtime MQTT contract. `ScheduleJsonRpcCodec` is the production interface and its factory selects exactly one implementation for the negotiated major:

- `ScheduleJsonRpcCodecV1` decodes and writes temperature-only points;
- `ScheduleJsonRpcCodecV2` uses `kind` and omits `temp` for ON/OFF.

Common envelope, list, range, and JSON Schema handling lives in the shared codec base. Point serialization remains isolated in each version implementation. Unknown major versions fail explicitly and must get a dedicated implementation before they are enabled.

The selected codec exposes `supportedSetpointKinds`. Repository and `DeviceScheduleApi` pass that typed capability through without interpreting a protocol major. Editors use it to expose only the supported kinds.

Configuration-driven controls use that same negotiated codec. `GetDeviceFull`
applies the runtime contracts from the resolved configuration bundle, and
`DeviceSnapshotBuilder` creates the schedule codec from that resolved
`schedule` contract before it asks `ControlStateResolver` to construct UI
state. Do not use a fixed V1 encoder for schedule bindings: an ON/OFF point
must be serialized by the V2 codec when the resolved bundle selects
`schedule@2`.

The shared editor sequence is `OFF -> 10.0...40.0 C -> ON`. New list points inherit the preceding typed setpoint and otherwise default to `21.0 C`.

Range mode remains a separate `ScheduleRange {min,max}` domain model and must not use typed ON/OFF setpoints.
