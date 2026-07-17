# User guide architecture

The user guide is an app-level feature. Its progress is stored per installation,
not per account or device.

The feature owns only reusable guide infrastructure: the progress repository,
`UserGuideCubit`, modal guide, shared illustration, spotlight overlay, and the
presentation-level `UserGuideHostRegistry`. It must not import `devices` or any
other feature-specific UI. A feature that wants a contextual guide owns its
targets, coach content, and interaction adapter in that feature's presentation
layer.

`UserGuideCubit` loads and owns the completed topic set. Topic identifiers are
versioned so that content can evolve without replaying the whole guide. Only
topics explicitly integrated as contextual coach overlays are shown
automatically; additional topics are manual by default.

The first topic teaches the upward gesture for thermostat live metrics. Its
thermostat-specific gate, target host, coach, and step model live under
`devices/details/presentation/user_guide`. The automatic coach and dashboard
both drive a single `ThermostatLiveMetricsInteractionController`. The real
live-metrics sheet follows the user's finger. Opening it does not finish either
the automatic or manual coach: closing the sheet restores the same guide step.
The automatic topic is persisted only when the user explicitly leaves it with
Skip or system Back while the sheet is closed. The coach remains a visual and
semantic layer: it clips blur above the rising sheet and exposes an accessible
tap alternative to the drag gesture.

Opening the guide from settings first pops the root navigator back to its root
route and waits for the next frame. A thermostat dashboard registers its topic
in `UserGuideHostRegistry` only while it is mounted and has supported live
tiles. The gate starts an automatic contextual session after the first eligible
dashboard is mounted. A settings action starts the same contextual session with
a manual source. Both sources show the same progressively disclosed steps above
the real device UI:

1. drag the real live-metrics sheet;
2. tap or hold the real thermostat mode bar;
3. tap the real temperature carousel to edit the active mode.

Stable target keys are owned by `ThermostatUserGuideTargetHost`, while the
spotlight coach measures those targets and blocks only the surrounding UI. This
keeps the highlighted controls directly interactive. Accessible text actions
provide alternatives to drag and long-press gestures.

If the selected root device cannot host this topic, settings opens the existing
demonstration modal instead of switching devices. Removing the last registered
host ends an active session so the cubit cannot remain suspended without a
renderer. Cancelling an automatic session this way does not complete it, so the
next eligible thermostat can start it again.

Opening a real sheet or editor does not finish the contextual session. While the
destination is visible, it owns pointer, Back, and accessibility interaction.
Closing it restores the same guide page. `Back / Next` changes pages explicitly;
performing the demonstrated action never advances or closes the guide. Explicit
exit from an automatic session persists topic completion for this installation.
Explicit exit from a manual session only suppresses an automatic replay for the
current app session and does not modify persisted completion. If the current
thermostat mode is OFF, tapping the temperature card opens a compact
editable-mode chooser instead of becoming a dead interaction.

The reusable modal `PageView` remains available for future non-contextual guide
topics. It closes through X or system Back and intentionally has no final Done
button.

`UserGuideCubit` is registered as a DI factory and is owned exactly once by the
root `BlocProvider(create:)`. The registry is a presentation-scoped singleton
provided through `RepositoryProvider`; repositories and `SharedPreferences`
remain explicit constructor dependencies.
