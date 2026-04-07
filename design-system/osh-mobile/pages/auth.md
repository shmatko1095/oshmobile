# Auth Page Overrides

Use `MASTER.md` as the base. This file describes the current auth implementation.

## Layout

- Centered single-column form via `AuthPageScaffold`.
- Content padding is `24` on all sides.
- Vertical rhythm is intentionally loose:
  - `24` between title/subtitle and form body,
  - `24-30` between fields,
  - `14-28` between actions.
- Footer can be pinned to the bottom on sign-in.

## Visual Rules

- Auth titles use the display scale (`34 / 700`) and are centered.
- Inputs use the shared dark filled field style from the global theme.
- Primary CTA uses the shared blue filled button.
- Google sign-in uses the same button geometry with a surface-colored background override.
- Secondary links are mixed in the current implementation:
  - sign-up inline CTA uses the primary accent,
  - `Try demo` uses secondary text styling,
  - `Forgot your password` uses underlined secondary text,
  - `Go to login` uses the default text button accent color.

## Interaction

- Keyboard dismisses on drag.
- Password visibility icon is muted while hidden and blue while revealed.
- Loading treatment currently swaps the main CTA for a centered `CupertinoActivityIndicator` instead of keeping the button shell visible.
- Sign-up uses a two-step flow with `AnimatedSwitcher` and a compact progress indicator.

## Keep As-Is

- Existing form order, validation, and bloc events.
- Existing sign-in / sign-up / forgot password navigation.
