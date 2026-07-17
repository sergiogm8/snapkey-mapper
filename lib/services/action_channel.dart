import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/installed_app.dart';
import '../models/snap_key_action.dart';
import '../models/trigger_log_entry.dart';

/// Single wrapper around the two native MethodChannels
/// (`snapkey_mapper/config`, `snapkey_mapper/service`) — every Dart↔Kotlin
/// call funnels through here rather than scattering channel/method name
/// strings across widgets.
class ActionChannel {
  ActionChannel._();

  static const MethodChannel _configChannel = MethodChannel(
    'snapkey_mapper/config',
  );
  static const MethodChannel _serviceChannel = MethodChannel(
    'snapkey_mapper/service',
  );

  /// In-memory only — reset on every fresh process start (e.g. app relaunch).
  /// Installed apps rarely change mid-session, so re-opening the action
  /// picker within the same session skips the native re-query entirely.
  static List<InstalledApp>? _installedAppsCache;

  static Future<void> setActionConfig(SnapKeyAction action) {
    return _configChannel.invokeMethod<void>('setActionConfig', {
      'json': jsonEncode(action.toJson()),
    });
  }

  static Future<SnapKeyAction> getActionConfig() async {
    final json = await _configChannel.invokeMethod<String>('getActionConfig');
    if (json == null) return const NoAction();
    return SnapKeyAction.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  static Future<void> startService() {
    return _serviceChannel.invokeMethod<void>('start');
  }

  static Future<void> stopService() {
    return _serviceChannel.invokeMethod<void>('stop');
  }

  /// Whether the user has enabled mapping (`service_should_run` flag) — not a
  /// live "is the OS process actually alive right now" check.
  static Future<bool> isServiceEnabled() async {
    final result = await _serviceChannel.invokeMethod<bool>(
      'isServiceShouldRun',
    );
    return result ?? false;
  }

  /// Whether the native Service object is actually alive right now in this
  /// process (companion `isRunning` flag set in onCreate/onDestroy) — the
  /// live counterpart to [isServiceEnabled]'s persisted intent. The two can
  /// disagree right after a fresh install/process death, before
  /// MainActivity's launch-time reconciliation catches up.
  static Future<bool> isServiceRunning() async {
    final result = await _serviceChannel.invokeMethod<bool>(
      'isServiceRunning',
    );
    return result ?? false;
  }

  static Future<bool> isPostNotificationsGranted() async {
    final result = await _serviceChannel.invokeMethod<bool>(
      'isPostNotificationsGranted',
    );
    return result ?? false;
  }

  static Future<ActionExecutionResult> testTrigger() async {
    final result = await _serviceChannel.invokeMapMethod<String, dynamic>(
      'testTrigger',
    );
    return ActionExecutionResult.fromMap(result ?? const {});
  }

  static Future<List<TriggerLogEntry>> getTriggerLog() async {
    final result = await _serviceChannel.invokeListMethod<Object?>(
      'getTriggerLog',
    );
    if (result == null) return const [];
    return result
        .map(
          (entry) => TriggerLogEntry.fromMap(entry as Map<Object?, Object?>),
        )
        .toList();
  }

  static Future<bool> isNotificationPolicyGranted() async {
    final result = await _serviceChannel.invokeMethod<bool>(
      'isNotificationPolicyGranted',
    );
    return result ?? false;
  }

  static Future<void> openNotificationPolicySettings() {
    return _serviceChannel.invokeMethod<void>(
      'openNotificationPolicySettings',
    );
  }

  /// "Display over other apps" (`SYSTEM_ALERT_WINDOW`) — holding it exempts
  /// the app from Background Activity Launch restrictions, so triggered
  /// actions launch directly instead of via a notification.
  static Future<bool> isOverlayGranted() async {
    final result = await _serviceChannel.invokeMethod<bool>(
      'isOverlayGranted',
    );
    return result ?? false;
  }

  static Future<void> openOverlaySettings() {
    return _serviceChannel.invokeMethod<void>('openOverlaySettings');
  }

  static Future<bool> isFullScreenIntentGranted() async {
    final result = await _serviceChannel.invokeMethod<bool>(
      'isFullScreenIntentGranted',
    );
    return result ?? false;
  }

  static Future<void> openFullScreenIntentSettings() {
    return _serviceChannel.invokeMethod<void>(
      'openFullScreenIntentSettings',
    );
  }

  /// Generic fallback fix action (opens the app's own system settings page) —
  /// used when a permission was denied once and re-requesting it directly
  /// would silently no-op (e.g. POST_NOTIFICATIONS after a first denial).
  static Future<void> openAppSettings() {
    return _serviceChannel.invokeMethod<void>('openAppSettings');
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    final result = await _serviceChannel.invokeMethod<bool>(
      'isBatteryOptimizationIgnored',
    );
    return result ?? false;
  }

  static Future<void> requestBatteryOptimizationExemption() {
    return _serviceChannel.invokeMethod<void>(
      'requestBatteryOptimizationExemption',
    );
  }

  /// Best-effort — see SnapKeyMethodChannelHandler.openAutostartSettings.
  /// There is deliberately no matching "isAutostartEnabled" check: ColorOS
  /// exposes no public API to query this state.
  static Future<void> openAutostartSettings() {
    return _serviceChannel.invokeMethod<void>('openAutostartSettings');
  }

  /// Opens the system Settings app's home screen (`Settings.ACTION_SETTINGS`)
  /// — see [PermissionStatus.openSnapKeySettings] for why this isn't a direct
  /// deep link to the Snap Key screen itself.
  static Future<void> openSystemSettings() {
    return _serviceChannel.invokeMethod<void>('openSystemSettings');
  }

  /// Session-cached: the native query runs once per app launch unless
  /// [forceRefresh] is set. Installed apps are static enough for a single
  /// session that re-querying on every picker open is wasted work.
  static Future<List<InstalledApp>> getInstalledApps({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _installedAppsCache != null) {
      return _installedAppsCache!;
    }
    final result = await _serviceChannel.invokeListMethod<Object?>(
      'getInstalledApps',
    );
    final apps = result == null
        ? const <InstalledApp>[]
        : result
              .map(
                (entry) =>
                    InstalledApp.fromMap(entry as Map<Object?, Object?>),
              )
              .toList();
    _installedAppsCache = apps;
    return apps;
  }

  /// Lazily fetches a single app's launcher icon as PNG bytes, decoded and
  /// rasterized natively on demand (not bundled into [getInstalledApps]).
  /// Returns null if the icon can't be loaded (e.g. the app was uninstalled
  /// between list load and this call) — callers should fall back to a
  /// placeholder rather than treating that as an error.
  static Future<Uint8List?> getAppIcon(String packageName) {
    return _serviceChannel.invokeMethod<Uint8List>('getAppIcon', {
      'packageName': packageName,
    });
  }
}

/// Result of a manual `testTrigger` call.
class ActionExecutionResult {
  const ActionExecutionResult({
    required this.actionLabel,
    required this.success,
    this.errorMessage,
  });

  factory ActionExecutionResult.fromMap(Map<Object?, Object?> map) {
    return ActionExecutionResult(
      actionLabel: map['actionLabel'] as String? ?? '',
      success: map['success'] as bool? ?? false,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  final String actionLabel;
  final bool success;
  final String? errorMessage;
}
