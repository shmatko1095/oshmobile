# Home Page Overrides

Use `MASTER.md` as base. This file defines only home-specific adjustments.

## Layout

- Keep current structure: AppBar + Drawer + content host.
- Keep current device-config-driven home composition (hero temperature + mode selector + sensor/info cards).

## Drawer / Device Menu

- Drawer background uses `color.bg.canvas`.
- Header and item blocks use solid dark cards (`color.bg.surface`) with large radius.
- Remove visible outer gray borders from item cards.
- Keep online/offline status indicator semantic (`success`/muted).

## Device Items

- One density for all rows: same paddings, icon size, title/subtitle typography.
- Long-press and swipe-to-unassign behavior stays unchanged.
- Destructive swipe uses shared destructive token pair.

## Keep As-Is

- Existing navigation and selection behavior.
- Existing MQTT activity icon behavior.
