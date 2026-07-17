# SnapKey Mapper

[![Support me on Ko-fi](assets/ko-fi/support_me_on_kofi_beige.png)](https://ko-fi.com/sgmdev)

Turns the Oppo Find X9's **Snap Key** hardware button into a custom, user-configurable shortcut. Download [here](https://github.com/sergiogm8/snapkey-mapper/releases/download/SnapKey-Mapper-1.0.0/snapkey-mapper.apk)

## The problem

The Snap Key has no public Android keycode — ColorOS handles it below the input layer and locks it
to a fixed preset list (Do Not Disturb, camera, AI Mind Space/Notes, sound/vibration). There is no
developer API for arbitrary remapping, and root is not available or desired.

## The workaround

The Snap Key's long press — the only independently assignable gesture on this device — is bound, in
ColorOS system settings, to the built-in **"Do Not Disturb"** preset. Toggling DND fires the system
broadcast `NotificationManager.ACTION_INTERRUPTION_FILTER_CHANGED`, which a normal (non-root) app can
observe once the user grants Notification Policy Access. SnapKey Mapper watches for the DND-on edge
and fires a user-configured action in response — DND itself is left on.

**Known trade-off:** any DND toggle from any source (Quick Settings tile, another automation, etc.)
is indistinguishable from a real Snap Key press and will also be intercepted. This is a deliberate
limitation of the approach, not a bug.

## Configurable actions

- **Open app** — launch any installed app
- **Open URL** — open a link in the default browser
- **Set alarm** — create an alarm (fires silently, without opening the Clock app's UI)
- **Play/Pause media** — toggle whatever app currently holds media focus

The action model is a small extensible sum type, mirrored between Dart and Kotlin — adding a new
action type means adding one case on both sides, not a schema migration.

## Architecture

The trigger → action pipeline is a **native Kotlin foreground service**, not a Dart background
isolate — a full Flutter engine/isolate is a far more killable footprint under ColorOS's aggressive
background process management than a lean native `Service`. Flutter's job is limited to
configuration UI (permission checklist, action picker, trigger log); once configured, the native
side keeps working even if the Flutter engine isn't running.

## Requirements

- Android 8.0+ (`minSdk 26`)
- Built and tested specifically against an Oppo Find X9 running ColorOS — other ColorOS/OPPO/Realme
  devices with a similar hardware button *may* work but aren't verified, and OEM settings screens
  referenced by the setup checklist (autostart, background-activity control) are version-specific
  and may differ on other builds
- No root required

## Setup checklist (in-app)

On first launch, the app walks you through everything it needs, since none of it is optional for a
background trigger to actually survive on ColorOS:

1. Bind the Snap Key's long-press to Do Not Disturb (device settings — the app can only meet you at
   the general Settings screen, ColorOS exposes no direct deep link here)
2. Grant Notification Policy Access (to observe the DND broadcast)
3. Grant Post Notifications (for the persistent "active" notification)
4. Grant "Display over other apps" (lets actions launch directly, without a notification)
5. Grant Full-screen intent access (fallback when the above is off)
6. Exempt from battery optimization (standard Android)
7. Allow background activity in ColorOS's own battery control (separate from, and not covered by,
   the standard Android permission above)
8. Allow autostart (survives reboot)

## Support

If this saved your Snap Key from being stuck on a preset you never use, consider
[buying me a coffee on Ko-fi](https://ko-fi.com/sgmdev).
