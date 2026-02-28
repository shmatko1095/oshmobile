# Mobile Refactor For Device Profile Bundle

This document captures the current mobile architecture and the target refactor required to support:
- device-side contract negotiation through `contracts.state`
- backend-provided `profile bundle`
- stable `control_id` driven widget gating and command routing

The goal is to make the app work with the current thermostat model `T1A-FL-WZE` using the artifacts now stored in `osh-device-protocol`.

Identity rule:
- `model_id` is the stable UUID used by backend, bundle payloads, and mobile logic
- `model_name` is the human-readable model label such as `T1A-FL-WZE`
- presenter selection and bundle compatibility must key off `model_id`, not `model_name`

Catalog rule:
- do not infer control types from ad hoc strings like `enum` or `collection`
- keep `valueSchemaRef` / `inputSchemaRef` in the bundle as the canonical protocol metadata
- current mobile runtime still uses explicit per-control UI hints for settings field type/widget selection; do not reintroduce substring-based inference from schema refs
- treat bindings as a separate validated DSL defined by `schemas/binding_catalog.schema.json`

## Current implementation analysis

### 1. Runtime contracts are negotiated per device session

Files:
- `lib/core/contracts/bundled_contract_defaults.dart`
- `lib/core/contracts/device_runtime_contracts.dart`
- `lib/core/contracts/contract_negotiator.dart`

Current state:
- device session bootstrap reads `contracts.state`, negotiates per-domain schema majors, and applies them to a device-scoped runtime resolver
- MQTT repositories no longer read schema ids from a global active contract singleton
- `BundledContractDefaults.v1` remains only as a bundled v1 default for bootstrapping, tests, and compatibility helpers

### 2. Transport/session layer is reusable

Files:
- `lib/core/network/mqtt/device_mqtt_repo_impl.dart`
- `lib/core/common/services/mqtt_session_controller.dart`

Current state:
- MQTT connection lifecycle and JSON-RPC request/notification transport are already separated enough to reuse
- this layer should stay and should not be rewritten during the refactor

### 3. Device details config is bundle-driven

Files:
- `lib/features/devices/details/domain/queries/get_device_full.dart`
- `lib/features/devices/details/presentation/cubit/device_page_cubit.dart`
- `lib/core/profile/profile_bundle_repository_impl.dart`

Current state:
- device details bootstrap now fetches backend `profile bundle` after negotiation
- production runtime no longer falls back to a built-in thermostat bundle when backend fetch fails
- Thermostat bundle fixture lives only under `test/support/`

Important separation rule:
- `model_profile` is model-scoped and must stay schema-agnostic
- negotiated schema ids come from device `contracts.state` plus app support
- control/action routing uses bindings selected after negotiation

### 4. Main thermostat widgets are hardcoded

Files:
- `lib/features/devices/details/presentation/presenters/thermostat_presenters.dart`
- `lib/features/devices/details/presentation/presenters/device_presenter.dart`

Current state:
- thermostat dashboard widgets are hardcoded in Dart
- visibility is controlled by config flags
- this is compatible with the new approach: keep widgets hardcoded, but gate them by profile bundle `widget_id` and `control_id`

### 5. Telemetry remains legacy-shaped internally, but widgets read via control ids

Files:
- `lib/core/network/mqtt/profiles/thermostat/thermostat_signals.dart`
- `lib/features/devices/details/data/mqtt_telemetry_repository.dart`

Current state:
- device snapshot now exposes control-state derived from bundle bindings, and thermostat widgets should read that layer
- telemetry repository still keeps a legacy alias map internally for compatibility with older slices
- some legacy widget ids (`powerNow`, `inletTemp`, `outletTemp`, `deltaT`) do not have matching data in current `telemetry@1`

This layer must be replaced with a control-state resolver based on `control_id` bindings.

### 6. Settings UI is generated from bundle profile plus app-side field hints

Files:
- `lib/features/settings/data/settings_contract_schema_catalog.dart`
- `lib/features/settings/data/json_schema_settings_ui_schema_builder.dart`
- `lib/app/device_session/data/device_facade_impl.dart`

Current state:
- settings groups and field visibility come from `model_profile` plus binding availability
- field widget/type metadata is currently supplied by explicit mobile-side hints keyed by `control_id`
- brittle type inference from `valueSchemaRef` has been removed

This should move to:
- backend `model_profile` for settings groups/order
- split binding catalogs for field routing
- negotiated schema major for runtime selection
- later, richer UI metadata can be derived from JSON Schema refs without reintroducing substring guessing

### 7. Schedule flows are already close to the target model

Files:
- `lib/features/schedule/data/schedule_jsonrpc_codec.dart`
- `lib/features/schedule/data/schedule_repository_mqtt.dart`
- `lib/features/schedule/presentation/open_mode_editor.dart`
- `lib/features/devices/details/presentation/presenters/widgets/thermostat_mode_bar.dart`

Current state:
- schedule logic is already expressed as `mode`, `points`, `range`
- these flows should stay, but should be invoked through `control_id` aware bindings instead of hardcoded global contracts

### 8. About/diagnostics domains are already separated

Files:
- `lib/features/device_about/data/device_about_repository_mqtt.dart`
- `lib/features/device_about/data/device_about_jsonrpc_codec.dart`

Current state:
- `device.state` is already isolated into its own repository
- this can be kept and later generalized under the same profile bundle architecture

## Target architecture

### Keep

- MQTT transport/session stack
- JSON-RPC client
- device session scope/facade pattern
- hardcoded screens and widget composition
- schedule editors and most view widgets

### Replace or add

1. Add `DeviceContractsRepository`
   - responsibility: read retained `contracts.state`, fallback to `contracts.get`, cache latest bootstrap contract

2. Add `ContractNegotiator`
   - responsibility: intersect app-supported schema majors with device-supported schema majors per domain
   - output: negotiated schema set and feature availability

3. Add `ProfileBundleRepository`
   - responsibility: request backend `profile bundle` by serial after negotiation

4. Replace `DeviceConfig` with `DeviceProfileBundle`
   - responsibility: expose `model_profile`, merged control catalogs, and merged bindings

5. Add `ControlBindingRegistry`
   - responsibility: resolve binding by `control_id` plus negotiated schema

6. Add `ControlStateResolver`
   - responsibility: materialize current atomic control values from domain snapshots using binding kinds from the catalogs

7. Add small app-side derived resolvers
   - ambient metrics from `telemetry_climate_sensors` + `sensors_items`
   - schedule summary from `schedule_mode` + `schedule_points_*` + `schedule_range`

8. Replace alias-driven `ThermostatSignals`
   - widgets should read by `control_id`, not by alias strings like `sensor.temperature`

9. Change widget gating
   - show widget only if:
     - widget id exists and is enabled in `model_profile`
     - all required controls exist in the profile
     - matching bindings exist for negotiated schema ids
     - required feature flags from `contracts.state` are satisfied

10. Replace mock config loading
   - keep `GetDeviceFull` as the bundle bootstrap boundary
   - configuration must come only from backend profile bundle plus device negotiation

## Current thermostat target behavior

For `T1A-FL-WZE`, the refactored app should show:
- `heroTemperature`
- `modeBar`
- `heatingToggle`
- `loadFactor24h`

It should not show:
- `powerNow`
- `inletTemp`
- `outletTemp`
- `deltaT`

Reason:
- current `telemetry@1` does not expose matching protocol data

## Recommended new mobile modules

- `lib/core/contracts/device_contracts_repository.dart`
- `lib/core/contracts/contract_negotiator.dart`
- `lib/core/profile/profile_bundle_repository.dart`
- `lib/core/profile/models/device_profile_bundle.dart`
- `lib/core/profile/models/model_profile.dart`
- `lib/core/profile/models/control_binding.dart`
- `lib/core/profile/control_binding_registry.dart`
- `lib/core/profile/control_state_resolver.dart`

## Phased migration plan

### Phase 1: bootstrap and data plumbing

- parse `contracts.state`
- negotiate schema ids
- fetch backend profile bundle
- apply negotiated contracts before feature repositories start
- hold both in one device-session state object

### Phase 2: read-only controls

- replace telemetry alias system with `ControlStateResolver`
- wire hero, mode bar, heating tile, load factor tile through atomic control ids
- derive ambient temperature/humidity in app from `telemetry_climate_sensors` + `sensors_items`
- derive current/next schedule summary in app from `schedule_mode`, `schedule_points_*`, `schedule_range`
- hide unsupported legacy tiles

### Phase 3: writable controls

- route schedule actions by `control_id`
- route settings fields by `control_id`
- use `patch` by default for writable settings fields

### Phase 4: cleanup

- remove `ThermostatSignals`
- keep built-in profile bundle fixture test-only
- remove any remaining local schema copies once backend bundle is the only source for settings layout

## Acceptance criteria

1. App can read `contracts.state` and compute negotiated schemas.
2. App can fetch a backend profile bundle by device serial.
3. Dashboard widgets are shown/hidden only from `model_profile`.
4. Dashboard widgets read values through `control_id` bindings.
5. Schedule mode bar and editors keep working with `schedule@1`.
6. Settings page is driven from `model_profile` groups plus bindings, not mock config.
7. Legacy tiles without current protocol support are absent for `T1A-FL-WZE`.
