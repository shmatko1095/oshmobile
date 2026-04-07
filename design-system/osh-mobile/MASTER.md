# OSH Mobile UI Design System (Master)

> Global source of truth for the current OSH Mobile UI as implemented in Flutter.
> Goal: document the existing visual system so page docs match the running app.

---

## Scope

- Platform: **mobile only** (Flutter).
- This folder describes the **current implementation baseline**, not a future redesign target.
- Keep existing information architecture, navigation, and business logic.
- When code and docs diverge, update the docs only after verifying the current implementation.

---

## Product Context

- Product type: smart home / thermostat control.
- UX mode: operational dashboard with quick checks and quick actions.
- Visual priority: dark-first readability, clear status communication, comfortable touch targets on primary flows.

---

## Visual Direction

- The app is **dark-first**, built around a pure black canvas.
- Main surfaces are dark charcoal cards with large rounded corners.
- Shared controls rely on a bright blue primary accent for CTAs, selected states, and focused controls.
- Subtle white borders and separators are used in several flows, especially device details, schedule, and secondary state screens.
- Status colors are more expressive than in the previous One UI draft:
  - green for online/success,
  - blue for active controls and selection,
  - red for warning/hot/destructive emphasis,
  - amber/orange/cyan as utility accents in some metric cards and info states.

---

## Global Tokens

### Color Tokens

| Token | Value | Usage |
|---|---|---|
| `color.bg.canvas` | `#000000` | App background, drawer background, main dark canvas |
| `color.bg.surface` | `#181818` | Default dark card surface |
| `color.bg.surfaceRaised` | `#1B1B1B` | Raised cards, inputs, secondary button backgrounds |
| `color.bg.surfaceAlt` | `#242424` | Alternate dark surface, disabled button background, secondary emphasis |
| `color.border.soft` | `rgba(255,255,255,0.07)` | Subtle card/input outline |
| `color.border.glass` | `rgba(255,255,255,0.08)` | Rare slightly stronger outline |
| `color.separator` | `rgba(255,255,255,0.09)` | Internal dividers |
| `color.text.primary` | `#F5F7FA` | Main text |
| `color.text.secondary` | `#B8BDCC` | Secondary text and labels |
| `color.text.muted` | `#8D94A5` | Muted text, hints, disabled supporting text |
| `color.accent.primary` | `#3779FC` | Primary actions, selected states, focused inputs, links |
| `color.accent.success` | `#34C759` | Online/success state |
| `color.accent.warning` | `#FF5252` | Hot/warning emphasis in current implementation |
| `color.accent.error` | `#EF4444` | Error/destructive state |
| `color.destructive.bg` | `rgba(239,68,68,0.12)` | Swipe-to-delete background |
| `color.destructive.fg` | `#F87171` | Destructive foreground/icon color |

### Utility Accent Tokens

These are not global semantics, but they are currently used in metric/status cards:

| Token | Value | Usage |
|---|---|---|
| `color.utility.orange` | `#FFAB40` | Delta/heating/power accents |
| `color.utility.cyan` | `#18FFFF` | Cool/negative delta accent |
| `color.utility.amber` | `#FFC107` | Informational warning card/background |
| `color.utility.amberStrong` | `#FFD740` | Power icon accent |

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
| `motion.slow` | `240ms` | Slower state/sheet transitions |

---

## Typography

The app mixes theme-level text styles with a few explicit metric sizes. Use these as the documentation baseline:

| Role | Size | Weight | Line Height |
|---|---|---|---|
| `display` | `34` | `700` | `1.15` |
| `screenTitle` | `24` | `700` | `1.2` |
| `bodyLarge` | `16` | `400-600` | `1.4` |
| `bodyMedium` | `14` | `400-600` | default Material |
| `bodySmall` | `12-13` | `500` | `1.35` |
| `sectionTitle` | `18` | `600` | `1.3` |
| `metricLarge` | `28-30` | `700-800` | `1.0-1.1` |
| `metricHero` | `56-78` | `300-600` | `0.95-1.0` |

Notes:

- Auth titles use `34 / 700`.
- App bars and major headings use `24 / 700`.
- Device hero/picker screens use the largest metric scale.
- Secondary labels usually sit on `text.secondary` or `text.muted`.

---

## Component Rules

### App Background & AppBar

- Dark theme uses `color.bg.canvas` for scaffold and drawer backgrounds.
- Primary app bars are centered and inherit canvas styling.
- Several secondary pages use a transparent app bar over the same dark canvas.
- Long titles are truncated with ellipsis.

### Cards

- Shared card wrappers are `AppSolidCard` and `AppGlassCard`.
- Default dark card surfaces use `color.bg.surface` or `color.bg.surfaceRaised`.
- Large radii (`24-28`) are standard across drawer cards, settings groups, hero panels, and metric tiles.
- Current implementation **does allow outlines**:
  - settings groups are mostly borderless,
  - details and schedule cards often use a subtle soft border,
  - selected or active cards may use a blue or red-tinted border.

### Buttons

- Primary buttons are accent-blue filled, height `50-52`, radius `16`, horizontal padding `16`.
- Disabled buttons use `surfaceAlt` with muted text.
- Secondary buttons are often implemented by overriding the shared button background to a surface color.
- Floating action buttons currently use a surface background plus shadow, not an accent fill.

### Inputs

- Shared input shape: dark filled field, radius `16`, subtle border, blue focus border.
- Dark filled input background is `surfaceRaised`.
- Error border uses `accentError`.
- Password visibility icons switch between muted and primary accent colors.

### Switches / Sliders / Chips

- Switch ON = blue track with white thumb.
- Switch OFF = dark gray track and light thumb.
- Slider active track follows primary accent blue.
- Selected chips/segments typically use translucent blue fill plus a blue border.
- Unselected chips are often transparent with secondary text.

### Lists / Groups

- Drawer menus are composed of individual rounded cards on a black canvas.
- Settings groups use rounded card containers with internal `Divider`s between rows.
- List tiles generally use `16` horizontal padding.
- Destructive swipe states use the shared red destructive palette.

### Status Treatment

- Online: green.
- Offline or urgent state emphasis: current implementation frequently uses red.
- Heating active: warm gradient, red/orange accent.
- Informational device compatibility / unsupported states may use amber surfaces or accent badges.

---

## Interaction Patterns

- Safe areas are respected across primary flows.
- Pull-to-refresh is used on drawer lists, settings, and device detail hosts.
- Swipe-to-delete is used in schedule and device list flows.
- Animated optimistic state is used in thermostat mode switching.
- Motion is short and functional, mostly fades, opacity changes, progress bars, and simple transform transitions.

---

## Shared Implementation References

- Theme tokens: `lib/core/theme/app_palette.dart`
- ThemeData and component themes: `lib/core/theme/theme.dart`, `lib/core/theme/component_themes.dart`
- Shared cards/buttons: `lib/core/common/widgets/app_card.dart`, `lib/core/common/widgets/app_button.dart`

---

## Documentation Rules

- Treat this file as the baseline for **what exists today**.
- Page files in `design-system/osh-mobile/pages/` describe screen-specific behavior and visual deviations.
- If a screen intentionally differs from this master, document that difference in the page override instead of changing the master.
