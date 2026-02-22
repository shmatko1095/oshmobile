# Settings Page Overrides

Use `MASTER.md` as base. This file defines only settings-specific adjustments.

## Layout

- Keep grouped card structure and schema-driven rendering.
- Preserve About card location and save/discard logic.

## Visual Rules

- Group containers are solid dark cards with large corner radius.
- **No visible outer gray frame** around group cards.
- Internal row separators are subtle and low-contrast.
- Switch style follows One UI dark behavior (blue ON, gray OFF).

## AppBar Action

- Save action uses accent color only when enabled.
- Disabled save uses muted token color.

## Messaging

- Keep unsaved-changes confirmation pattern.
- Error/retry states reuse shared status styling.

## Keep As-Is

- Existing schema rendering and validation logic.
- Existing save/discard behavior.
