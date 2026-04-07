# Settings Page Overrides

Use `MASTER.md` as the base. This file describes the current settings implementation.

## Layout

- Keep the schema-driven grouped card structure.
- Page padding is `12` horizontal with stacked sections.
- Preserve the trailing `About` card and current save/discard flow.

## Visual Rules

- Settings groups are rendered as rounded cards using the global card theme.
- Group cards currently rely on card surface color and shape, without an explicit outer accent border.
- Rows inside groups are separated by low-contrast `Divider`s.
- Titles use compact bold text, with supporting copy in muted body-small text.
- Save action uses the accent color only when there are unsaved changes, otherwise it falls back to disabled color.

## Controls

- Toggle rows use `ListTile + Switch.adaptive` with the shared switch theme.
- Slider rows use a title/value row, full-width slider, and min/max captions.
- Select rows use a trailing dropdown.
- Read-only rows stay in the same grouped list treatment as editable rows.

## Messaging

- Unsaved changes use a standard alert dialog.
- Errors are surfaced through snackbars.
- Full-screen load/retry states are centered and use the same global button styling.

## Keep As-Is

- Existing schema rendering, patching, validation, and save/discard behavior.
