# Mobile Client Policy And Update UX Plan

## Summary
- Goal: notify users about new app versions and hard-block unsupported versions when needed.
- Backend status: implemented in `osh-be` with persistent storage and audit history.
- Source of truth for policy (v1): `mobile-service` DB (`mobile_client_policy` + `mobile_client_policy_history`).
- Public check endpoint access: `permitAll` (works before auth restore).

## Current Backend Architecture (osh-be)
- Mobile app calls public HTTP endpoint on `bff`: `GET /v1/mobile/client-policy`.
- Admin manages policy via `bff` admin endpoints:
  - `GET /v1/admin/mobile/client-policy/{platform}`
  - `PUT /v1/admin/mobile/client-policy/{platform}`
- `bff` delegates policy operations to `mobile-service` over gRPC.
- `mobile-service` evaluates status using strict app version parsing (`x.y.z`) and stores policy/history in PostgreSQL.

## Target Behavior (mobile app UX)
- App checks policy on startup using platform/app version.
- App re-checks policy when app returns to foreground (`resumed`).
- Policy status drives UX:
  - `allow`: continue startup.
  - `recommend_update`: continue startup + show non-blocking modal.
  - `require_update`: show blocking update screen before entering app or immediately on foreground re-check.
- If policy endpoint is unavailable:
  - use cached last successful policy fields if available;
  - if cache is missing, fail-open (allow app entry), log degradation.

## Public API Contract (for mobile app)
- Endpoint: `GET /v1/mobile/client-policy`
- Query params:
  - `platform`: `android|ios` (required)
  - `app_version`: strict `x.y.z`, example `1.8.2` (required)
  - `build`: integer, optional (observability/debug only, not used for decision in v1)
- Response fields:
  - `status`: `allow|recommend_update|require_update`
  - `min_supported_version`
  - `latest_version`
  - `store_url`
  - `checked_at` (Unix timestamp in UTC seconds, number; fractional seconds allowed)
  - `policy_version`
- Validation:
  - invalid or missing query params -> `400`.

## Admin API Contract (for policy management)
- `GET /v1/admin/mobile/client-policy/{platform}`:
  - returns current policy for `android` or `ios`.
- `PUT /v1/admin/mobile/client-policy/{platform}`:
  - payload:
    - `min_supported_version`
    - `latest_version`
    - `store_url`
    - `policy_version`
  - constraints:
    - versions must be strict `x.y.z`
    - `min_supported_version <= latest_version`
    - `store_url` must be valid `http/https`
    - `policy_version > 0` and strictly greater than current
  - conflict behavior:
    - non-increasing `policy_version` -> `409 Conflict` (`POLICY_VERSION_CONFLICT`).

## Decision Rules
- `app_version < min_supported_version` -> `require_update`
- `min_supported_version <= app_version < latest_version` -> `recommend_update`
- `app_version >= latest_version` -> `allow`

## Policy Update Workflow (actual v1 flow)
- Policy is updated via admin API (not via static BFF config).
- Recommended release flow:
  1. Read current policy for platform.
  2. Prepare new values (`min_supported_version`, `latest_version`, `store_url`).
  3. Increase `policy_version` (strictly monotonic).
  4. Send `PUT /v1/admin/mobile/client-policy/{platform}`.
  5. Verify decision through public endpoint with test versions.

## Mobile Plan (oshmobile)
- Add startup policy fetch right after connectivity check and before normal auth gate routing.
- Add foreground policy fetch on lifecycle `resumed`.
- Add policy domain model and cache model:
  - cache policy fields (`min_supported_version`, `latest_version`, `store_url`, `policy_version`, `checked_at`, `fetched_at`);
  - do not cache final `status` as source of truth; recalculate status for current app version.
- Add UI:
  - `recommend_update`: startup modal with `Update now` and `Later`.
  - `require_update`: full-screen blocking gate with store CTA only.
- Soft-update cadence:
  - if user taps `Later`, suppress recommend prompt for current `policy_version` until policy changes.
- Add request headers to OSH API requests (BFF endpoints only, not OIDC token requests):
  - `X-App-Platform`
  - `X-App-Version`
  - `X-App-Build`
- Analytics/events:
  - policy fetched (with status),
  - prompt shown,
  - update CTA tapped,
  - later tapped,
  - fallback-to-cache and fail-open cases.

## Failure Handling Matrix
- No internet at startup:
  - keep current startup behavior (`No internet` screen + retry).
- Internet is available, but `GET /v1/mobile/client-policy` fails (`5xx`, timeout, parse error):
  - if cached policy exists: recompute status from cached policy + current app version;
  - if cache is missing: fail-open and continue app flow, log degradation.
- Public endpoint returns `404 CLIENT_POLICY_NOT_FOUND`:
  - treat as backend misconfiguration; apply same fallback as above (cache -> fail-open).
- Public endpoint returns `400`:
  - treat as client bug in request params; fail-open for user flow, report non-fatal with high priority telemetry.

## UI/UX Requirements
- Reuse existing visual language (`AppPalette`, current card/button patterns).
- Accessibility:
  - high contrast text,
  - clear title/subtitle and explicit action labels,
  - no color-only communication.
- Motion:
  - subtle transitions only (current app motion tokens), no aggressive animation.

## Documentation References
- Mobile plan doc: `oshmobile/docd/mobile-client-policy-plan.md`.
- Backend API doc: `osh-be/platform/mobile-service/MOBILE_CLIENT_POLICY_API.md`.

## Test Plan
- Mobile unit/widget tests:
  - startup state transitions for `allow/recommend_update/require_update`,
  - foreground (`resumed`) re-check transitions, including switching to blocking gate from an already opened app session,
  - fallback behavior (cached policy and no-cache fail-open),
  - modal and blocking screen rendering/CTA behavior,
  - app-version headers attached by network interceptor.
- Mobile integration tests:
  - contract parsing for `checked_at` (numeric Unix timestamp), `policy_version`, `status`,
  - behavior for `400/404/5xx` responses.

## Explicit Decisions Locked
- v1 decision is based on `app_version` only.
- `build` is optional and observability-only in v1.
- `platform` values in v1: `android`, `ios`.
- App version format in v1: strict numeric `x.y.z` only.
- Recommended update UX: startup modal, non-blocking.
- Recommended prompt suppression: once per `policy_version` (show again only after policy update).
- Outage strategy: fail-open with cache preference.
- Cache strategy: cache policy fields, recompute status locally for current app version.
- Lifecycle checks: evaluate policy on startup and on every foreground resume.
- Forced update is a safety net, not a replacement for `/v1/mobile` compatibility discipline.
