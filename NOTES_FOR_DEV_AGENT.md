# SnapKey Mapper — context for implementation

## Problem
The Oppo Find X9 "Snap Key" has no public Android keycode — it's handled by ColorOS below the
input layer and locked to a fixed preset list (DND, camera, AI Mind Space/Notes, sound/vibration).
There is no developer API for arbitrary remapping, and root is not available/desired.

Workaround: bind the Snap Key's **long press** (the only assignable gesture on this device — short
and double press are not independently assignable) to the built-in "Do Not Disturb" preset. DND
toggles fire the system broadcast `NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED`, which a
normal (non-root) app can observe once the user grants "Notification Policy Access"
(`Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS`). The app detects the DND-on edge and fires a
user-configured custom action — turning the Snap Key long-press into a custom action trigger. DND
itself is left on (an earlier revert-DND feature was dropped, see `CLAUDE.md`).

## Decisions already locked in (do not re-litigate)
- v1 scope: exactly **one** shortcut, driven only by the DND signal.
- The fired action is configurable via an in-app Tasker-style picker, not hardcoded. Action set: open
  an installed app, open a URL, set an alarm, play/pause media — designed to be extensible.
- Runtime must be a **native Kotlin foreground service** with a persistent notification (not a Dart
  headless isolate), so the trigger/action-execution path survives independent of the Flutter
  engine's lifecycle. Flutter is the control-panel UI only; native Kotlin is the self-sufficient
  runtime.

## Known accepted limitation
Any DND toggle from any source (not just the Snap Key — e.g. Quick Settings tile, another
automation) will be intercepted and treated as if the Snap Key fired. There's no way to distinguish
the source. This is an accepted trade-off, not a bug to fix in v1.

## Authoritative plan
The architecture design (native service design, data flow, manifest permissions, minSdk/targetSdk,
file responsibilities, verification steps) was never written to a standalone plan file — read
`CLAUDE.md` at the project root first, it captures the same decisions in condensed form.

## UI design
`design/DESIGN.md` has the concrete Material 3 spec for both screens, imported from a Claude Design
mockup (raw source kept in `design/reference/` for provenance only — not buildable code). Read it
before writing `home_screen.dart`/`action_picker_screen.dart`. `ToggleTorch` was considered and
dropped from scope.

## Task breakdown
`TASKS.md` at the project root is the ordered, incremental implementation plan (8 phases, each task
independently verifiable). Work through it in order and check items off as they're completed —
later phases depend on earlier ones actually working, not just existing.

## Current state of this repo
All 8 phases in `TASKS.md` have code written (Phases 1-5 device-tested, three real bugs found and
fixed — see that file's Status section; Phases 6-7 implemented and compile clean but device
verification is still the user's step). Read `TASKS.md` for the authoritative, current state of
every phase — this section is intentionally not duplicated here since it would go stale;
`TASKS.md` is the source of truth for progress, this file is for background/context only.
