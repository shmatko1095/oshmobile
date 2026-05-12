# Mobile Session Provisioning API Usage Guide

## Purpose
- Describe how the mobile app should use the new backend endpoint that ensures local user provisioning.
- Prevent runtime failures in device operations when a Keycloak user exists but no local user row exists in user-service.

## Scope Of This Document
- This document describes API usage and app-flow integration guidance.
- This document does not include implementation changes in this iteration.

## API Contract

### Endpoint
- Method: POST
- Path: /v1/mobile/me/session
- Auth: required Bearer JWT (real user session)
- Request body: none
- Success response: 204 No Content

### Semantics
- The endpoint ensures a local user exists in user-service for the current JWT subject.
- The operation is idempotent by user id:
  - local user already exists -> 204
  - local user is created now -> 204
- Demo principal behavior: no-op success (do not provision shared demo account).

### Request Headers
- Authorization: Bearer <access_token>
- Standard mobile app headers may still be sent:
  - X-App-Platform
  - X-App-Version
  - X-App-Build

## Important Implementation Constraint
- The ensure call must include Authorization even when it runs before the app emits its normal authenticated state.
- Preferred implementation for the current app architecture:
  - persist/store the real session first,
  - call this endpoint through the normal `MobileV1Service` / Chopper client,
  - emit authenticated/session-ready UI state only after the ensure call succeeds.
- This is the preferred path because the current auth flow already stores session data before authenticated-state emission, so the normal authenticated client can attach the bearer token without introducing a second request path.
- Keep an explicit-token request path only as a fallback if the normal client path cannot be made reliable.
- Do not call this endpoint before the client can attach the bearer token; that would turn a valid login into a false `401`.

## Provisioning Scope In The Auth Lifecycle
- Session provisioning is part of real sign-in completion and restored-session startup.
- Session provisioning should not run on every generic background token refresh used only to replay a failed API request.
- If implementation splits refresh paths, startup/auth bootstrap should use a provisioning-aware path, while generic API-authenticator refresh should remain token-refresh-only.

## When To Call The Endpoint
1. Real sign-in flow:
- Call the endpoint after obtaining a real user session token.
- Complete app transition to normal authenticated/session-ready state only after ensure call succeeds.

2. Restored-session startup flow:
- Call the endpoint during auth bootstrap before startup is considered ready for normal device UI.

3. Repeated calls:
- Repeated calls for the same user are safe and should still return success.

4. Demo flow:
- Skip explicit call from app for demo sessions.

## Integration Notes For App Flow

### Real Sign-In Path (Password/Google)
1. Obtain session tokens from identity flow.
2. Persist/store the real session so the normal authenticated client can attach Authorization.
3. Call POST /v1/mobile/me/session through the normal `MobileV1Service` path.
4. On 204, continue to normal authenticated/session-ready app flow.

### Restored Session Path
1. Refresh/restore session.
2. Persist/store the refreshed session if token data changed.
3. Call POST /v1/mobile/me/session.
4. On 204, continue startup to ready state.

## Error Handling Guidance

### 401/403
- Meaning: missing/invalid/expired auth context.
- Action: clear or reject the pending session and route to sign-in.

### 404
- Meaning: JWT subject cannot be resolved to identity state required by backend.
- Action: clear or reject the pending session, force re-authentication, and surface a user-safe message.

### 5xx/timeout/network unavailable
- Meaning: transient backend or connectivity issue.
- Action:
  - do not open normal authenticated device UI yet,
  - keep the valid session pending in startup/auth bootstrap retry or no-internet path,
  - retry through existing startup retry/resume mechanism,
  - do not advance startup/auth bootstrap to ready/authenticated state until ensure succeeds or the session is intentionally cleared for an auth/identity failure.

## Failure Classification
- Auth/identity failures (`401`, `403`, identity-missing `404`) should clear or reject the pending session and send the user back through sign-in.
- Transient failures (`5xx`, timeout, no internet) should not clear a valid pending session by themselves; keep startup blocked and retry through the existing startup retry/resume path.
- Unknown failures should be treated conservatively as transient for user flow, but reported as non-fatal telemetry for investigation.
- Sign-in and startup flows must surface ensure failures as controlled auth/startup states. Do not allow the provisioning call to fail as an uncaught Bloc/Cubit exception while the UI proceeds.

## Retry Policy
- Retry only transient failures (network timeout, 5xx).
- Do not use unlimited aggressive retry loops.
- Reuse existing startup retry and foreground resume triggers where applicable.

## Observability Recommendations
- Log and track the following signals:
  - session ensure attempt started,
  - session ensure success,
  - session ensure failed (with normalized category: auth, not_found, transient, unknown),
  - fallback usage detected server-side (temporary rollout period).

## Validation Checklist
- Real sign-in -> ensure call returns 204 before first mutable device action.
- Restored session -> ensure call returns 204 before startup ready/authenticated state.
- Ensure request includes Authorization before authenticated UI state is emitted.
- Repeated calls for same user remain successful.
- No JWT call returns 401.
- Demo flow does not create a local user.
- Generic background API token refresh does not itself trigger session ensure.
- Transient startup ensure failure does not advance startup to ready/authenticated state.

## Chopper Client Update Notes
- Add a method similar to `ensureMySession()` to `MobileV1Service` with `@POST(path: '/me/session')`.
- Preferred implementation uses the normal authenticated client after session storage, because the current auth flow already persists session data before authenticated-state emission.
- After changing the Chopper service interface, regenerate generated code:

```bash
cd /home/oshmatko/osh/oshmobile
dart run build_runner build --delete-conflicting-outputs
```

## Example HTTP Call

POST /v1/mobile/me/session
Authorization: Bearer <access_token>
X-App-Platform: android
X-App-Version: 1.0.12
X-App-Build: 23

Expected response:
- 204 No Content

## Rollout Notes
- During initial rollout, backend may keep lazy bootstrap fallback as a safety net.
- Target end state remains explicit session ensure as the primary path.
- After rollout confidence is achieved, fallback usage should trend to zero and can be removed in backend follow-up.

## Related References
- osh-be plan for session provisioning: /home/oshmatko/osh/osh-be/plan.md
- existing mobile policy doc style reference: /home/oshmatko/osh/oshmobile/docd/mobile-client-policy-plan.md
