# Prompt: Refactor oshmobile To Device Profile Bundle

Use this prompt when implementing the mobile refactor.

```text
You are refactoring the Flutter mobile app in /home/oleksandr/osh/oshmobile/lib to support:
- runtime device contract negotiation via MQTT `contracts.state`
- backend-provided device profile bundle
- stable control ids (`control_id`) instead of alias-based telemetry keys

Important context from the current codebase:

1. Runtime contracts are negotiated per device session today:
- lib/core/contracts/bundled_contract_defaults.dart
- lib/core/contracts/device_runtime_contracts.dart
- lib/core/contracts/contract_negotiator.dart

2. MQTT transport/session is already reusable and should be preserved:
- lib/core/network/mqtt/device_mqtt_repo_impl.dart
- lib/core/common/services/mqtt_session_controller.dart

3. Device bootstrap already uses backend profile bundle and must stay that way:
- lib/features/devices/details/domain/queries/get_device_full.dart
- lib/features/devices/details/presentation/cubit/device_page_cubit.dart
- lib/core/profile/profile_bundle_repository_impl.dart

4. Main thermostat widgets are hardcoded and should remain hardcoded for now:
- lib/features/devices/details/presentation/presenters/thermostat_presenters.dart

5. Telemetry aliasing is legacy and must be removed:
- lib/core/network/mqtt/profiles/thermostat/thermostat_signals.dart
- lib/features/devices/details/data/mqtt_telemetry_repository.dart

6. Settings UI currently depends on local hardcoded schema maps and model hints:
- lib/features/settings/data/settings_contract_schema_catalog.dart
- lib/features/settings/data/json_schema_settings_ui_schema_builder.dart
- lib/app/device_session/data/device_facade_impl.dart

Shared source-of-truth artifacts are now in /home/oleksandr/osh/osh-device-protocol:
- schemas/model_profile.schema.json
- schemas/profile_bundle.schema.json
- schemas/control_catalog.schema.json
- schemas/action_catalog.schema.json
- schemas/binding_catalog.schema.json
- catalogs/controls/*.controls.json
- catalogs/actions/*.actions.json
- catalogs/bindings/*@1.bindings.json
- models/T1A-FL-WZE/model_profile.json
- docs/model-profile-architecture.md
- docs/profile-bundle.md
- docs/models/T1A-FL-WZE-control-matrix.md

Identity rule:
- `model_id` is the stable UUID used in mobile runtime logic
- `model_name` is the human-readable model label such as `T1A-FL-WZE`
- do not key presenter selection, widget gating, or bundle lookup off `model_name`

Catalog format rule:
- controls expose `valueSchemaRef`, not ad hoc `type`
- actions expose `inputSchemaRef`, not ad hoc payload descriptors
- keep schema refs in bundle models as canonical metadata, but do not reintroduce substring-based type inference from them
- bindings are validated by `binding_catalog.schema.json`; for `patch_operation` use `payloadKey`

Target outcome:
- The app negotiates schema majors from `contracts.state`.
- The app fetches backend `profile bundle` by serial.
- The production runtime must not silently fall back to a built-in thermostat bundle.
- Hardcoded widgets are shown/hidden using profile widget ids.
- Widgets read/write through control ids and binding kinds, not through alias strings.
- The app works for the current thermostat model T1A-FL-WZE.

Constraints:
- Keep MQTT transport/session architecture.
- Keep hardcoded screen composition.
- Do not reintroduce raw protocol paths into the model profile.
- Do not put concrete schema ids like `settings@1` into the model profile; keep them in negotiation state and binding selection.
- Use `patch` by default for writable settings.
- Hide unsupported legacy thermostat tiles: `powerNow`, `inletTemp`, `outletTemp`, `deltaT`.

Implement the refactor in phases:

Phase 1:
- Keep `DeviceContractsRepository`, `ContractNegotiator`, `ProfileBundleRepository`, and bundle models as the canonical bootstrap path.
- Ensure device session bootstrap applies negotiated contracts before feature repositories start watching MQTT state.
- Remove any silent local bundle fallback from production runtime.

Phase 2:
- Keep `ControlBindingRegistry`.
- Keep `ControlStateResolver` for these binding kinds:
  - `state_snapshot`
  - `patch_field`
  - `patch_operation`
- Replace legacy alias-based telemetry access in thermostat widgets with control-id reads.
- Add app-side derived helpers:
  - ambient metrics from `telemetry_climate_sensors` + `sensors_items`
  - schedule summary from `schedule_mode` + `schedule_points_*` + `schedule_range`

Phase 3:
- Route schedule writes through atomic schedule controls:
  - `schedule_mode`
  - `schedule_points_*`
  - `schedule_range`
- Route settings writes through `patch_field`.
- Rebuild settings UI from `model_profile.integrations.osh.settings_groups` and control bindings.
- Keep explicit app-side `control_id -> field type/widget` hints until JSON Schema-driven UI metadata is implemented.

Phase 4:
- Remove `ThermostatSignals`.
- Keep built-in thermostat bundle only as a test fixture.
- Remove any remaining local schema copies from `SettingsContractSchemaCatalog`.

Deliverables:
1. New domain models and repositories for contracts/profile bundle.
2. Updated device session flow using negotiated schemas + backend bundle.
3. Thermostat presenter wired to `control_id` based state reads.
4. Settings page driven from backend profile + bindings.
5. Tests for:
   - contract negotiation
   - control binding resolution
   - control state derivation
   - widget gating for T1A-FL-WZE

Acceptance criteria:
1. `heroTemperature`, `modeBar`, `heatingToggle`, `loadFactor24h` render for T1A-FL-WZE.
2. `powerNow`, `inletTemp`, `outletTemp`, `deltaT` stay hidden for T1A-FL-WZE.
3. Schedule mode switching and editors still work with `schedule@1`.
4. Settings page no longer depends on mock config or local hardcoded protocol schemas.
5. Runtime code can support future `@2` domains by adding bindings instead of rewriting model profile.

Work pragmatically:
- reuse existing transport/session code,
- preserve working UI where possible,
- do not over-abstract beyond the fixed binding kinds listed above.
```
