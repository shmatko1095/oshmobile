# OSH Mobile UI Design System (Master)

> Global source of truth for UI unification.
> Goal: make all screens consistent and visually close to Samsung One UI (dark), without changing core flows.

---

## Scope

- Platform: **mobile only** (Flutter).
- Use only mobile interaction rules and mobile layout constraints.
- Keep existing information architecture, navigation, and business logic.
- Improve visual consistency, spacing, states, and readability.

---

## Product Context

- Product type: smart home / thermostat control.
- UX mode: operational dashboard (quick checks, quick actions).
- Priority: clarity, touch comfort, predictable controls.

---

## Visual Direction (Samsung One UI Dark)

- Canvas is pure black.
- Surfaces are dark graphite cards with large rounded corners.
- No visible gray outer card frames by default.
- Internal separators are subtle (inside grouped cards).
- Accent blue is used only for active controls (switches, primary action, links).

---

## Global Tokens

### Color Tokens

| Token | Value | Usage |
|---|---|---|
| `color.bg.canvas` | `#000000` | App background |
| `color.bg.surface` | `#111217` | Primary cards, groups, drawers |
| `color.bg.surfaceRaised` | `#151821` | Elevated content blocks |
| `color.bg.surfacePressed` | `#1B202A` | Pressed/selected states |
| `color.border.subtle` | `rgba(255,255,255,0.06)` | Optional rare outline |
| `color.separator` | `rgba(255,255,255,0.10)` | Internal dividers |
| `color.text.primary` | `#F5F7FA` | Main text |
| `color.text.secondary` | `#B5BAC8` | Secondary labels |
| `color.text.muted` | `#8D94A5` | Hint/disabled text |
| `color.accent.primary` | `#2B7CFF` | Primary actions, active toggles |
| `color.accent.success` | `#34C759` | Online/success state |
| `color.accent.warning` | `#F59E0B` | Warning |
| `color.accent.error` | `#EF4444` | Errors/destructive |

### Spacing Tokens

| Token | Value |
|---|---|
| `space.xs` | `4` |
| `space.sm` | `8` |
| `space.md` | `12` |
| `space.lg` | `16` |
| `space.xl` | `24` |
| `space.2xl` | `32` |

### Radius Tokens

| Token | Value |
|---|---|
| `radius.sm` | `12` |
| `radius.md` | `16` |
| `radius.lg` | `24` |
| `radius.xl` | `28` |
| `radius.pill` | `999` |

### Motion Tokens

| Token | Value | Notes |
|---|---|---|
| `motion.fast` | `120ms` | Press/toggle feedback |
| `motion.base` | `180ms` | Default transitions |
| `motion.slow` | `240ms` | Sheets/modals |
| `motion.curve` | `easeOutCubic` | Default easing |

---

## Typography

Use current app type scale, but enforce consistency by token role.

| Role | Size | Weight | Line Height |
|---|---|---|---|
| `display` | `34` | `700` | `1.15` |
| `screenTitle` | `24` | `700` | `1.2` |
| `sectionTitle` | `18` | `600` | `1.3` |
| `body` | `16` | `400` | `1.4` |
| `bodyStrong` | `16` | `600` | `1.4` |
| `caption` | `13` | `500` | `1.35` |
| `metricLarge` | `28` | `700` | `1.1` |
| `metricXL` | `56` | `300-600` | `1.0` |

---

## Component Rules

### App Background & AppBar

- App background must be `color.bg.canvas`.
- AppBar uses transparent or canvas background, no blue tint.
- Title center + ellipsis for long names.

### Cards

- Default card = solid dark surface with large radius.
- No mandatory outer border.
- Use separators **inside** grouped cards instead of card outlines.

### Buttons

- Primary button height `50-52`, radius `radius.md`, horizontal padding `16`.
- Disabled state uses muted foreground + pressed surface background.
- Loading state keeps width/height fixed.

### Inputs

- One input style across auth/settings/forms.
- Dark filled field with subtle border and clear focus accent.
- Avoid bright/light field backgrounds in dark mode.

### Switches / Sliders / Chips

- Switch ON = `color.accent.primary`, OFF = muted gray.
- Slider active track follows accent color.
- Chips/segments require clear selected state (background + text weight).

### Lists / Settings Groups

- Settings groups are big rounded cards.
- Rows inside groups separated by subtle internal divider.
- Icons, paddings, and row density are unified.

---

## Mobile-Only Interaction Rules

- Minimum touch target: `44x44`.
- Minimum spacing between adjacent touch targets: `8`.
- Respect safe areas and gesture/navigation bars.
- Keep one-handed reach in mind for primary actions.
- Keep animations short and purposeful.

---

## Rollout Plan

1. **P0 Foundation**
- Finalize color/surface/radius tokens for One UI dark.
- Align ThemeData component themes.

2. **P1 Shared Components**
- Consolidate button/input/card style usage.
- Remove ad-hoc borders and blue backgrounds.

3. **P2 Screen Unification**
- Home drawer/list and settings groups first.
- Device details and schedule second.
- Auth/secondary pages third.

4. **P3 Visual QA**
- Validate on common phone widths and dark mode only.
- Check contrast, divider consistency, and state colors.

---

## Definition of Done

- Black canvas everywhere in app dark theme.
- No blue-tinted page backgrounds.
- No gray card outlines in side menu/settings.
- Shared styles drive buttons/inputs/cards/switches.
- Major screens feel like one product family and align with One UI dark language.
