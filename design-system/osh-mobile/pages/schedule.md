# Schedule Page Overrides

Use `MASTER.md` as base. This file defines only schedule-specific adjustments.

## Layout

- Keep existing list-based editor and day filter bar.
- Keep current picker-based editing flow.

## Visual Rules

- Schedule tiles reuse the same dark card language as details/settings.
- Day chips use one selected style token set (not ad-hoc per screen).
- FAB and action buttons follow shared accent + radius tokens.

## Interaction

- Preserve swipe-to-delete gesture.
- Keep time/temp edit flow unchanged.
- Ensure chip and stepper targets stay at least `44x44`.

## Feedback

- Error/retry view follows shared status component style.

## Keep As-Is

- Existing cubit logic.
- Existing weekly/day filtering model.
