# Home Page Overrides

Use `MASTER.md` as the base. This file describes the current home implementation.

## Layout

- Structure stays `AppBar + Drawer + selected-device content host`.
- App bar title is centered and truncated with ellipsis.
- App bar actions currently include MQTT activity status and a settings icon.

## Drawer / Device Menu

- Drawer background uses the global black canvas.
- Header, device items, add-device, and logout rows are rendered as separate rounded cards placed directly on the canvas.
- Normal cards are surface-based and borderless.
- Selected device rows use:
  - translucent blue background,
  - blue border,
  - stronger white title color.

## Device Items

- Row density is compact and consistent:
  - `16` horizontal / `12` vertical inner padding,
  - `18` status icon,
  - `17` title size with medium-to-bold weight.
- Room/secondary text uses muted styling.
- Long press opens rename.
- Swipe-to-unassign keeps the red destructive background and delete icon.

## Status Treatment

- Online indicator is green.
- Offline indicator currently uses the app warning/status red.
- Chevron stays visible on each row, with stronger contrast on the selected device.

## Keep As-Is

- Existing drawer navigation, device selection, and content host composition.
- Existing MQTT activity icon behavior.
