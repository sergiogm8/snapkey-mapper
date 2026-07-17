import 'action_channel.dart';

/// Checks status of ACCESS_NOTIFICATION_POLICY, POST_NOTIFICATIONS, and
/// full-screen-intent access (all needed for the trigger pipeline to be
/// visible/effective — see CLAUDE.md), plus battery-optimization exemption
/// and the best-effort ColorOS autostart deep link (Phase 7). ColorOS exposes
/// no API to query autostart state, so there's no `isAutostartEnabled` — only
/// an action to open the settings screen.
class PermissionStatus {
  PermissionStatus._();

  static Future<bool> isNotificationPolicyGranted() {
    return ActionChannel.isNotificationPolicyGranted();
  }

  static Future<void> openNotificationPolicySettings() {
    return ActionChannel.openNotificationPolicySettings();
  }

  static Future<bool> isPostNotificationsGranted() {
    return ActionChannel.isPostNotificationsGranted();
  }

  static Future<bool> isOverlayGranted() {
    return ActionChannel.isOverlayGranted();
  }

  static Future<void> openOverlaySettings() {
    return ActionChannel.openOverlaySettings();
  }

  static Future<bool> isFullScreenIntentGranted() {
    return ActionChannel.isFullScreenIntentGranted();
  }

  static Future<void> openFullScreenIntentSettings() {
    return ActionChannel.openFullScreenIntentSettings();
  }

  static Future<void> openAppSettings() {
    return ActionChannel.openAppSettings();
  }

  static Future<bool> isBatteryOptimizationIgnored() {
    return ActionChannel.isBatteryOptimizationIgnored();
  }

  static Future<void> requestBatteryOptimizationExemption() {
    return ActionChannel.requestBatteryOptimizationExemption();
  }

  static Future<void> openAutostartSettings() {
    return ActionChannel.openAutostartSettings();
  }

  /// Opens the system Settings app's home screen. There is no documented,
  /// verified deep link straight to ColorOS's Snap Key assignment screen —
  /// unlike [openAutostartSettings], which has real ColorOS safecenter
  /// component names to try, the Snap Key screen's location has varied
  /// across ColorOS/device versions with nothing stable to target. The user
  /// has to search/navigate to "Snap Key" themselves from here.
  static Future<void> openSnapKeySettings() {
    return ActionChannel.openSystemSettings();
  }
}
