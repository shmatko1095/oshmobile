# OSHMobile Mobile QA Agent Plan

## Goal

Build a mobile-only QA workflow for `oshmobile` that:

- launches the Flutter app on an Android emulator,
- exercises the main user flows,
- validates the UI in dark and light themes,
- records defects with screenshots and reproducible steps,
- produces a coverage report instead of an ad hoc narrative.

## Why Use Both An Agent And A Skill

Use a custom agent for orchestration and a skill for repeatable workflow assets.

- Agent responsibility:
  - verify that a mobile emulator is connected,
  - launch the app with `flutter run -d <emulator-id>`,
  - choose the next scenario to inspect,
  - enforce Android-only execution,
  - summarize findings and blockers.
- Skill responsibility:
  - provide a reusable checklist and report template,
  - keep the scenario matrix consistent across runs,
  - standardize evidence collection for dark and light themes.

## Current Feature Inventory

This inventory is based on the current Flutter structure, analytics screen names, design-system docs, and existing widget tests.

### 1. Startup And Entry

- connectivity check,
- mobile client policy check,
- no internet state,
- recommended update dialog,
- forced update blocking flow,
- auth gate between sign-in and home.

### 2. Auth

- sign in,
- sign up,
- sign up success,
- forgot password,
- demo mode entry,
- auth error handling,
- Google or Keycloak-based auth handoff.

### 3. Home And Drawer

- home with and without selected device,
- device list in drawer,
- selected device highlight,
- add device entry point,
- rename device,
- swipe to unassign,
- logout,
- MQTT activity indicator.

### 4. Device Dashboard

- hero temperature panel,
- mode bar and optimistic state updates,
- telemetry cards,
- pull to refresh,
- online and offline states,
- unsupported or unknown device-layout states.

### 5. Schedule

- schedule list rendering,
- edit time,
- edit target temperature,
- edit range,
- weekly day filter,
- swipe to delete,
- save and retry flows.

### 6. Device Settings

- grouped settings list,
- nested child groups,
- dirty state tracking,
- save,
- discard confirmation,
- toggle, slider, dropdown, and read-only rows.

### 7. Device Access

- assigned users list,
- current user marker,
- self-remove flow,
- remove confirmation,
- demo-mode restrictions.

### 8. Account Settings

- profile summary,
- profile page,
- theme selection,
- app version check,
- recommend update dialog,
- require update screen,
- account deletion request flow.

### 9. Device Provisioning And Device Metadata

- BLE Wi-Fi scan,
- Wi-Fi password step,
- device about,
- device catalog and assignment.

### 10. Telemetry History

- telemetry history open action,
- history chart rendering,
- empty state,
- load failure state,
- preview-to-full-history navigation.

## Theme Coverage Matrix

Every functional scenario should be checked in both `dark` and `light` themes.

For each area, validate:

- screen readability and contrast,
- safe-area compliance,
- clipped text and overflow,
- button prominence and disabled states,
- loading, empty, and error states,
- selection states,
- swipe actions and destructive affordances,
- dialogs, sheets, and overlays,
- scroll behavior on smaller screens.

## Evidence Format Per Scenario

For each executed scenario, collect:

- scenario id,
- feature area,
- theme,
- emulator device,
- preconditions,
- steps,
- expected result,
- actual result,
- pass or fail,
- screenshot path,
- notes or blocker.

## Suggested Execution Order

1. Confirm emulator visibility with `flutter devices` and `adb devices -l`.
2. Launch the app with `flutter run -d <emulator-id>`.
3. Establish entry path:
   - authenticated account,
   - demo mode,
   - device mock path if needed.
4. Run a smoke pass on dark theme.
5. Switch to light theme via account settings and rerun the same smoke pass.
6. Expand from smoke coverage into deeper feature-specific checks.
7. Produce a concise report with findings, screenshots, and blockers.

## First Milestone

The first practical milestone is not "test everything".

It is:

1. launch `oshmobile` on an Android emulator,
2. reach the auth or demo entry point,
3. confirm theme switching works,
4. cover startup, auth, home, device dashboard, settings, and account settings,
5. write the first coverage report with evidence.

## Exit Criteria For A Useful First Version

The first version of the agent is good enough when it can:

- refuse non-mobile targets,
- boot the app on Android emulator without manual command guessing,
- follow a fixed smoke matrix,
- compare dark and light themes for the same flows,
- report real blockers instead of silently skipping them.