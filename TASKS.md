# Implementation tasks

Ordered, incremental breakdown of the architecture in `CLAUDE.md` / `NOTES_FOR_DEV_AGENT.md` /
`design/DESIGN.md`. Each task is meant to be small enough to implement and manually verify on its
own before moving to the next — later tasks depend on earlier ones, but nothing here requires the
final UI to exist to be testable. Checked-off tasks are done; leave notes inline if a task's real
implementation diverges from what's written here.

Action set: `OpenApp`, `OpenUrl`, `SetAlarm`, `MediaPlayPause` (`ToggleTorch` considered, dropped —
see `CLAUDE.md`).

## Status

Phases 1-5 were device-tested on the Find X9; three real bugs were found and fixed:

1. **Persistent notification never appeared.** `POST_NOTIFICATIONS` is a runtime permission on
   Android 13+ — the manifest declaration alone isn't enough. Fixed: `MainActivity.onCreate`
   requests it unconditionally on launch.
2. **Interceptor "didn't work outside the app."** The "Mapping enabled" switch reflected the
   persisted `service_should_run` intent, not whether the Service was actually alive. Fixed:
   `MainActivity.onCreate` reconciles state on every launch, and `SnapKeyListenerService` exposes a
   live `isRunning` flag. Also fixed: `startForeground` needs the 3-arg overload with
   `ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE` on API 34+.
3. **Triggered action silently didn't open anything from a real DND toggle** (but worked from "Test
   action now"). Root cause: a direct `context.startActivity()` call is silently blocked by
   Background Activity Launch restrictions when the caller has no visible UI. Fixed: `ActionExecutor`
   launches via a notification (full-screen intent + tap-to-open) unless "Display over other apps"
   is granted, in which case it launches directly.

A DND-revert feature (turning DND back off immediately after firing the action) was implemented,
found to silently no-op on Android 15+ once `targetSdk >= 35` (the "implicit zen rules" change makes
`setInterruptionFilter(ALL)` unable to turn off DND activated by the user/system), and was then
removed rather than keep pinning `targetSdk` below Flutter's default to work around it —
`DndInterruptionReceiver` now only detects the edge and fires the action; DND is left on.

## Phase 1 — Config model & MethodChannel plumbing (no service, no UI yet)

- [x] **1.1** `android/.../ActionConfig.kt` — sealed class `OpenApp(packageName)` / `OpenUrl(url)` +
      `toJson()`/`fromJson()` (tagged JSON). Round-trip confirmed via a standalone `dart run` script.
- [x] **1.2** `lib/models/snap_key_action.dart` — Dart mirror of 1.1, same JSON shape.
- [x] **1.3** `MainActivity.kt` registers both `MethodChannel`s, routed to
      `SnapKeyMethodChannelHandler.kt`. Confirmed working on-device (config round-trips correctly).
- [x] **1.4** `lib/services/action_channel.dart` wraps both channels. Confirmed on-device via the
      debug UI (kept, not deleted — still the active debug screen through Phase 5).

## Phase 2 — Foreground service skeleton (always-on notification, no DND logic yet)

**This phase is what keeps the app "always on" independent of the UI.** Two Android behaviors are
in play, both must be handled explicitly, not assumed:
- A started `Service` outlives its launching `Activity` by default (`android:stopWithTask` defaults
  to `false`) — closing the app's UI (back button, task switcher) does **not** stop the service by
  itself. Don't set `stopWithTask="true"` anywhere.
- Swiping the app away from the **recents/multitasking list** is a different, harsher signal on
  ColorOS than a normal "close" — some OEM builds kill the whole process on task removal regardless
  of the manifest flag above. `onTaskRemoved()` is the defensive hook for this: override it to
  immediately re-`startForegroundService` itself. Combined with `START_STICKY` and the Phase 7
  battery/autostart exemptions, this is the realistic ceiling of what's controllable without root —
  document that ceiling rather than promising perfect survival.

- [x] **2.1** Manifest has `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE`,
      `POST_NOTIFICATIONS`, `USE_FULL_SCREEN_INTENT`, and the `<service>` declaration with
      `foregroundServiceType="specialUse"` + `PROPERTY_SPECIAL_USE_FGS_SUBTYPE`. No `stopWithTask`.
- [x] **2.2** `SnapKeyListenerService.kt` posts the persistent notification via a `NotificationChannel`
      (`IMPORTANCE_LOW`) using the 3-arg `startForeground` overload with
      `ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE` on API 34+ (fixed after on-device testing —
      see Status). `onStartCommand` returns `START_STICKY`. `onTaskRemoved()` re-launches itself.
      Exposes a live `isRunning` companion flag. `onDestroy` cancels the notification.
- [x] **2.3** `start`/`stop` wired on `snapkey_mapper/service` to
      `SnapKeyListenerService.start()`/`stop()` + a `service_should_run` flag in `SharedPreferences`.
      Notification appearing/disappearing confirmed on-device after the POST_NOTIFICATIONS fix.
      **Still needs a fresh on-device re-test of the swipe-from-recents survival step** specifically
      (was not isolated from the other bugs during today's pass) before fully trusting it.

## Phase 3 — Action execution (still trigger-less — fired manually)

A direct `context.startActivity()` call from `ActionExecutor` is silently blocked by Android's
Background Activity Launch restrictions whenever the caller has no visible UI (the real
service/receiver trigger path) — see `CLAUDE.md`. `ActionExecutor` launches directly when "Display
over other apps" is granted, otherwise falls back to a notification (full-screen intent +
tap-to-open).

- [x] **3.1** `ActionExecutor.kt` — reads `ActionConfig` fresh from `SharedPreferences` and launches
      each action type via the strategy above. Wrapped in try/catch.
- [x] **3.2** `testTrigger` method on `snapkey_mapper/service` calls `ActionExecutor.execute()`
      directly, bypassing DND entirely.

## Phase 4 — DND interception (the actual trick)

- [x] **4.1** Manifest has `ACCESS_NOTIFICATION_POLICY`. `lib/services/permission_status.dart` +
      native `isNotificationPolicyGranted`/`openNotificationPolicySettings` implemented and confirmed
      working on-device (checklist row correctly showed "Granted" after manually granting it).
- [x] **4.2** `DndInterruptionReceiver.kt` implemented (dynamically registered in
      `SnapKeyListenerService`, `RECEIVER_NOT_EXPORTED`). Detects a DND off→on edge and fires the
      configured action; does not revert DND. Confirmed on-device: edge-detection works,
      `ActionExecutor` fires on a genuine DND-on edge.

## Phase 5 — Trigger log

- [x] **5.1** `TriggerLogStore.kt` — capped ring buffer in `SharedPreferences`, JSON-encoded
      `{timestamp, actionLabel, success, error?}`. Confirmed on-device: new entries append correctly
      after both `testTrigger` and real DND-triggered fires (read directly from the SharedPreferences
      XML file via `adb shell run-as ... cat`).
- [x] **5.2** `getTriggerLog` + `lib/models/trigger_log_entry.dart` confirmed working. Debug UI now
      also auto-refreshes every 3s (added after on-device testing showed the log/service-state
      display otherwise only updated on manual pull-to-refresh or after tapping "Test action now").

## Phase 6 — Real UI per `design/DESIGN.md`

Implemented, compiles clean (`flutter analyze` info-only, `flutter test` passes, `flutter build apk
--debug` succeeds) — **not yet run on a device**, so treat every item below as "written correctly per
the spec and the existing service-layer contracts, not yet visually/behaviorally confirmed."

- [ ] **6.1** `lib/widgets/permission_tile.dart` — reusable checklist row (icon, two-line label,
      "Granted" pill or tappable "Fix"/"Open" pill). Added `showGrantedPill`/`actionLabel` params for
      the ColorOS autostart row (Phase 7), which has no queryable granted/denied state — only an
      action, not a pill.
- [ ] **6.2** `lib/screens/home_screen.dart` — app bar, mapping on/off hero card (shows a "starting/
      stopping…" subtitle when `isServiceEnabled`/`isServiceRunning` disagree, adapted from the debug
      UI's mismatch indicator rather than dropped), "when Snap Key is pressed" card with "Change" →
      `ActionPickerScreen`, "Test action now" (result now shown via `SnackBar`, not a static label),
      full setup checklist (notification policy, post-notifications, full-screen-intent, battery
      optimization, ColorOS autostart), recent activity list with a relative-time formatter. Keeps the
      debug UI's 3s `Timer.periodic` auto-refresh (confirmed necessary during Phase 1-5 on-device
      testing — the trigger log/live service state don't push updates, so this is a poll, not just a
      convenience).
- [x] **6.3** `getInstalledApps` native method added to `SnapKeyMethodChannelHandler.kt` (queries
      `ACTION_MAIN`/`CATEGORY_LAUNCHER`, returns packageName + label; icons are fetched lazily per
      row via `getAppIcon`, cached natively and in Dart). `lib/models/installed_app.dart` +
      `lib/screens/action_picker_screen.dart`: tabbed `SegmentedButton` (Open app / Open URL / Alarm
      / Media), searchable app list with radio selection, URL text field, "Save action" writes via
      `setActionConfig` and pops back to `HomeScreen`. Pre-selects/pre-fills from the currently
      configured action on open.
- [x] **6.4** `lib/main.dart` — real navigation: `SnapKeyMapperApp` → `HomeScreen` (→
      `ActionPickerScreen` via push). All Phase 1-5 debug buttons removed.
      **Verify (needs the physical device — not done by this pass):** full manual flow — open app,
      toggle mapping on, change action via picker, save, "Test action now" fires the newly-picked
      action, log updates and auto-refreshes.

## Phase 7 — Reboot survival & OEM battery/autostart

Implemented, compiles clean — **not yet verified on-device** (none of this is testable without a real
reboot / real OEM battery-settings UI / a real ColorOS build to confirm the autostart deep link
resolves).

- [ ] **7.1** `BootReceiver.kt` implemented — manifest now has `RECEIVE_BOOT_COMPLETED` +
      `<receiver>` declaration (`android:exported="true"`, required for the system to deliver a
      protected system broadcast to a manifest-registered receiver). Restarts the service via
      `SnapKeyListenerService.start()` if `ConfigStore.getServiceShouldRun()` is true.
      Verify: enable mapping, reboot the device without reopening the app, confirm the persistent
      notification reappears and a manual DND toggle still fires the action.
- [ ] **7.2** Battery-optimization exemption: `isBatteryOptimizationIgnored`/
      `requestBatteryOptimizationExemption` added to `SnapKeyMethodChannelHandler.kt`
      (`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, with a fallback to the generic app-details
      settings screen if that specific intent is disallowed on this OEM build) and wired into the
      Phase 6 checklist's "Fix" button.
- [ ] **7.3** Best-effort ColorOS autostart: `openAutostartSettings` tries two known
      `com.coloros.safecenter` component-name variants (catching `ActivityNotFoundException` between
      them), falls back to the generic app-details settings screen if neither resolves. No
      `isAutostartEnabled` check exists — ColorOS exposes no public API to query this state, so the
      checklist row is action-only (an "Open" pill, not a "Granted"/"Fix" pill), per
      `PermissionTile`'s new `showGrantedPill: false` mode.
      Verify: tap "Open" and confirm it actually lands on ColorOS's startup-manager screen (not just
      the generic app-details fallback) on this specific ColorOS version.

Also added, not in the original Phase 6/7 breakdown but needed to make the checklist actually
actionable: `openAppSettings` (generic `ACTION_APPLICATION_DETAILS_SETTINGS` fallback), used as the
"Fix" action for the post-notifications row — re-requesting a runtime permission after a user denial
can silently no-op, so routing to app settings is the reliable recourse there.

## Phase 8 — Final device verification

- [ ] **8.1** Full end-to-end pass on the physical Find X9 per the procedure in `CLAUDE.md`/the
      original design plan: bind the Snap Key long-press to DND in ColorOS settings, grant all
      permissions, configure an action, lock the phone, long-press the Snap Key, confirm the action
      fires and the trigger log updates — including after a reboot.
- [ ] **8.2** Deliberately toggle DND from Quick Settings while the service is running to confirm
      (not fix) the documented false-positive limitation, so it's a known, observed behavior rather
      than a surprise later.
- [ ] **8.3** Swipe the app away from the recent-apps list (kill the task, not just background it),
      wait a minute, then long-press the Snap Key and confirm the action still fires — this is the
      real "closing the app doesn't stop it" test, distinct from 8.1's reboot test.
