# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app (Android is the only configured platform)
flutter run

# Static analysis / lint
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Release build
flutter build apk
```

This project does not use FVM (no `.fvmrc` present) — use the plain `flutter`/`dart` binaries, not `fvm flutter`.

## What this app is

SnapKey Mapper turns the Oppo Find X9's "Snap Key" hardware button into a custom, user-configurable
shortcut. The Snap Key has no public Android keycode — ColorOS handles it below the input layer and
locks it to a fixed preset list (DND, camera, AI Mind Space/Notes, sound/vibration). There is no
developer API for arbitrary remapping, and root is not available/desired.

**Workaround the whole app is built around:** the Snap Key's long press (the only independently
assignable gesture on this device) is bound, in ColorOS system settings, to the built-in "Do Not
Disturb" preset — outside this app's control. Toggling DND fires the system broadcast
`NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED`, which a normal (non-root) app can observe
once the user grants Notification Policy Access
(`Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS`). The app detects the DND-on edge and fires a
user-configured action — DND itself is left on. (An earlier version also reverted DND back off after
firing; that was dropped — see `DndInterruptionReceiver.kt` — since Android 15's "implicit zen
rules" change makes `setInterruptionFilter(ALL)` unable to turn off DND activated by the user/system
once `targetSdk >= 35`, and this app tracks Flutter's default `targetSdk`.)

**Known accepted limitation:** any DND toggle from any source (Quick Settings tile, another
automation, etc.) is indistinguishable from a real Snap Key press and will also be intercepted. This
is a deliberate trade-off of the approach, not a bug to fix.

## Architecture: native runtime, Flutter control panel

The trigger → action pipeline is implemented as a **native Kotlin foreground service**, not a Dart
background isolate (`flutter_background_service` was deliberately rejected — a full Flutter
engine/isolate is a much larger, more killable footprint under ColorOS's aggressive background
process management than a lean native `Service`). Flutter's job is limited to configuration UI; once
configured, the native side must keep working even if the Flutter engine is not running.

- `android/app/src/main/kotlin/com/sgm/snapkeymapper/SnapKeyListenerService.kt` — the
  persistent foreground service. Owns the persistent notification, and dynamically registers (in
  code, not the manifest — `ACTION_INTERRUPTION_FILTER_CHANGED` is a protected broadcast that cannot
  be manifest-declared on modern Android) a `BroadcastReceiver` with `RECEIVER_NOT_EXPORTED` for DND
  changes. `DndInterruptionReceiver.kt` fires the configured action on a DND off→on edge; it does
  not revert DND.
- `ActionExecutor.kt` — reads the configured action from `SharedPreferences` fresh on every fire (no
  in-memory caching, so config changes from the UI apply on the very next trigger) and launches it.
  Launch strategy: if "Display over other apps" (`SYSTEM_ALERT_WINDOW`) is granted, it calls
  `context.startActivity()` **directly and silently (no notification)** — holding that grant is a
  documented exemption to Android's Background Activity Launch restrictions. Without it, a direct
  call from the service/receiver context is silently blocked by BAL (confirmed on-device:
  `startActivity()` doesn't throw when blocked, so it looks like it worked when it didn't; it only
  happened to work from the "Test action now" button because that call originates from the
  foreground app), so it falls back to **launching via a notification** (full-screen intent +
  tap-to-open). The fallback needs `USE_FULL_SCREEN_INTENT` (manifest) and, on API 34+, the
  user-grantable "Full screen intents" special-access toggle for the auto-launch-over-lock-screen
  behavior — without it, tap-to-open only. Both the overlay grant and the FSI grant have checklist
  rows in `home_screen.dart` (`isOverlayGranted`/`openOverlaySettings` on the service channel).
- `BootReceiver.kt` — manifest-registered `BOOT_COMPLETED` receiver; restarts the service after
  reboot if it was previously enabled, since `START_STICKY` alone does not survive a full reboot.
- `ConfigStore.kt` — reads/writes the action config as JSON. Config is written directly through a
  Kotlin `SharedPreferences` call reached via `MethodChannel`, **not** through Dart's
  `shared_preferences` plugin — that plugin prefixes keys with `"flutter."`, which would otherwise
  have to be replicated on the Kotlin side. Keeping one unambiguous writer avoids that footgun.
- The action model is a small extensible sum type — `OpenApp(packageName)`, `OpenUrl(url)`,
  `SetAlarm(hour, minute, label?, daysOfWeek)`, `MediaPlayPause` — mirrored between
  `ActionConfig.kt` and `lib/models/snap_key_action.dart`. Adding another action type means adding
  one case on both sides plus a tab in `action_picker_screen.dart`, not a schema migration.
  `ToggleTorch` was considered and dropped.

On the Dart side (`lib/`), everything routes through one `MethodChannel` wrapper
(`lib/services/action_channel.dart`) rather than scattering channel/method name strings across
widgets. `lib/screens/home_screen.dart` is the status screen (permission checklist, service on/off
toggle, a "test now" button that fires `ActionExecutor` directly without needing a real DND event,
and a recent-trigger log written by the native side so it's readable even after the Dart engine was
restarted). `lib/screens/action_picker_screen.dart` is the Tasker-style action configuration screen.

## UI design reference

`design/DESIGN.md` is the concrete visual spec for `home_screen.dart` and `action_picker_screen.dart`
(Material 3, imported from a Claude Design mockup) — the original mockup only covered the "Open
app"/"Open URL" tabs; the "Alarm"/"Media" tabs were added later following the same pattern.

## Implementation task breakdown

`TASKS.md` at the project root is the ordered, incremental implementation plan — 8 phases, each task
independently verifiable before moving to the next (config plumbing → foreground service skeleton →
action execution → DND interception → trigger log → real UI → reboot/battery/autostart survival →
final device verification). Work through it in order; it's the concrete to-do list this architecture
description sets up.

## Working conventions

- Never run `flutter test` (or any test command) unless the user explicitly asks for it in that
  message. `flutter analyze` and builds are fine without asking.
- When a change adds a new widget or new functionality, say in the final report of that turn
  whether unit tests or widget tests would be feasible/worthwhile for it, and only write them if
  the user says to.

## Current repo state

Fully implemented through the TASKS.md phases (Android-only — no iOS/web/desktop directories exist
by design, since this app is fundamentally OEM/ColorOS-specific): manifest permissions,
service/receiver declarations, MethodChannel wiring, both screens, and the native trigger pipeline
are all in place. See TASKS.md for remaining device-verification work.

Target platform constraints: `minSdk 26`, `targetSdk` tracks Flutter's default, package
`com.sgm.snapkeymapper`.
