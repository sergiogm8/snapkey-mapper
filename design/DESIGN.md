# UI design reference

Source: Claude Design project ["Mobile app Material 3 design"](https://claude.ai/design/p/9edc89b3-d8bb-4a31-85ea-a3f5aebb7942)
(`file=SnapKey+Mapper.dc.html`). Raw source files imported for provenance/diffing live in
`design/reference/` (`snapkey_mapper.dc.html`, `android-frame.jsx`) — these are Claude Design's own
canvas format (React + a `.dc.html` templating runtime), **not** buildable Flutter/Dart code. They
exist so this repo has its own copy of the design source instead of only a link, and so a future
re-import can diff against what's already here. Treat this document as the actual spec to implement
against; the raw files are reference only.

The mockup covers two screens, each in light and dark, Material 3 style, on a 412×892 Android device
frame. Colors are parameterized via OKLCH hue variables (`--hue-p` primary, `--hue-s` success/green,
`--hue-t` tertiary/accent) — translate this to Flutter with `ColorScheme.fromSeed(seedColor: ...)`
plus `ColorScheme.tertiary`/success-ish extension colors, not literal hardcoded hex. Corner radii and
spacing are also tokenized (`--r-sm/md/lg`, `--pad-*`, `--gap-*`) — mirror as a small `AppTheme`
constants set (e.g. `BorderRadius` values ~14/20/28) rather than magic numbers scattered through
widgets. Icons throughout are Material Symbols Outlined — map 1:1 to Flutter's `Icons` set (outlined
variants).

## Home screen (`lib/screens/home_screen.dart`)

Top to bottom:

1. **App bar** — leading icon in a rounded square (bolt/lightning icon, tinted primary-container
   background), title "SnapKey Mapper", trailing icon button (settings — not wired to anything in
   this mockup, can be a no-op/placeholder for now).
2. **Mapping status hero card** — full-width rounded card, primary-container background. Leading
   circular avatar with a power icon, "Mapping is on" headline, "Long-press Snap Key to fire your
   action" subtitle, trailing `Switch` reflecting service on/off. This is the service start/stop
   toggle from `ActionChannel.startService()`/`stopService()`.
3. **"When Snap Key is pressed" card** — section label, then a row: tinted icon matching the
   currently configured action (camera icon shown = `OpenApp` pointed at Camera), the action's
   display label ("Opens Camera"), and a "Change" chip/button on the right that navigates to
   `ActionPickerScreen`.
4. **"Test action now"** — outlined full-width button with a bolt icon and caption underneath
   ("Fires instantly — no need to press the key"). Wire to `ActionChannel.testTrigger()`.
5. **"Setup checklist" section** — card containing 3 rows, each: leading status icon, two-line
   label (title + explanation), trailing status chip. Chip is either a neutral "Granted" pill
   (success-tinted, non-interactive) or a "Fix" pill (tertiary/warning-tinted, tappable → opens the
   relevant system settings screen):
   - Notification access → granted/not-granted state, opens `ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS`.
   - Battery optimization → "Fix" opens the battery-optimization exemption request.
   - ColorOS autostart → "Fix" opens the best-effort ColorOS autostart settings deep link.
   This is exactly the permission checklist already planned — this mockup is its concrete visual spec.
6. **"Recent activity" section** — card containing a list of trigger-log rows: small check-circle
   icon, one-line description ("Opened Camera"), right-aligned relative timestamp. This is the
   recent-trigger log already planned, fed by `ActionChannel.getTriggerLog()`.

## Action picker screen (`lib/screens/action_picker_screen.dart`)

1. **Top bar** — back arrow + "Choose action" title, no elevation/tint (transparent app bar).
2. **Segmented control** — two-tab pill (`SegmentedButton` or a custom two-cell row): "Open app" /
   "Open URL". Active tab is filled with the primary color; inactive is transparent text.
3. **"Open app" tab** — a search field ("Search apps") followed by a scrollable list of installed
   apps, each row: tinted leading icon avatar, app name, trailing radio indicator (selected state
   shown as a thick-ringed selected radio). Backed by `ActionChannel.getInstalledApps()`.
4. **"Open URL" tab** — labeled "URL" section, an outlined text field with a link icon and
   placeholder `https://your-link.com`, helper text "Opens in your default browser when triggered".
5. **"Save action"** — full-width filled button pinned at the bottom, writes the selection via
   `ActionChannel.setActionConfig()`.

**Resolved scope change:** the mockup's tab control only offers "Open app" and "Open URL" — no third
"Toggle flashlight" tab. Decision: drop `ToggleTorch` from v1 scope entirely and build the picker
exactly as shown (2 tabs only). The `ActionConfig` model stays extensible so torch (or anything else)
can be added later as a third tab following the same pattern — but v1 has no camera/torch permission
handling, no `ToggleTorch` case in `ActionExecutor`, and no third tab in the picker.

## Implementation notes

- No new Flutter dependency is required to build these screens with real Material 3 widgets
  (`Card`, `Switch`, `SegmentedButton`, `ListTile`, `Chip`/`FilterChip`, `TextField`,
  `FilledButton`/`OutlinedButton`) — this is a standard Material 3 layout, not a custom design
  system needing a component library import.
- The mockup's "Recent activity" and "Setup checklist" card content in the screenshots (Camera
  action, all-granted permissions, populated log) are placeholder/example states for the design
  preview, not literal copy to hardcode — bind them to real state from `ActionChannel`.
