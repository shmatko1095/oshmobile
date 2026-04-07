# Schedule Page Overrides

Use `MASTER.md` as the base. This file describes the current schedule implementation.

## Layout

- Keep the list-based editor with swipe-to-delete rows.
- Weekly mode adds a bottom weekday filter bar.
- Secondary editors for time, temperature, and range use picker-based pages with transparent app bars.

## Visual Rules

- Schedule entries are raised dark cards with large radius and a subtle outer border.
- Time and temperature values are the visual anchors of each tile (`28 / 700`).
- Day chips use the current local pattern:
  - selected = translucent blue fill + blue border,
  - unselected = transparent background + secondary text.
- FAB is intentionally surface-colored with shadow and large rounding, not a solid accent button.
- Temperature stepper uses blue for decrement and current warning red for increment.

## Interaction

- Swipe-to-delete is preserved.
- Tapping time/value opens dedicated picker pages.
- Weekly day toggles use dense chips in both tile rows and the bottom filter bar.
- Controls in this screen are visually compact; the current implementation does not enforce a single global chip token beyond the local schedule styling.

## Feedback

- Error / retry state is simple:
  - centered message text,
  - outlined retry button.

## Keep As-Is

- Existing cubit logic and schedule data model.
- Existing weekly/day filtering and edit flow.
