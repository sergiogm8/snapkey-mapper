import 'package:flutter/material.dart';

import '../services/permission_status.dart';
import '../theme/app_theme.dart';
import 'permission_tile.dart';

/// "Setup checklist" card: one [PermissionTile] per permission the trigger
/// pipeline depends on, each wired to its own status flag and fix action.
class SetupChecklistCard extends StatelessWidget {
  const SetupChecklistCard({
    super.key,
    required this.notificationPolicyGranted,
    required this.postNotificationsGranted,
    required this.overlayGranted,
    required this.fullScreenIntentGranted,
    required this.batteryOptimizationIgnored,
  });

  final bool notificationPolicyGranted;
  final bool postNotificationsGranted;
  final bool overlayGranted;
  final bool fullScreenIntentGranted;
  final bool batteryOptimizationIgnored;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          PermissionTile(
            icon: Icons.touch_app,
            title: 'Snap Key bound to DND',
            subtitle:
                'Assign the Snap Key\'s long-press '
                'to "Do Not Disturb"',
            granted: false,
            showGrantedPill: false,
            actionLabel: 'Open Settings',
            onFix: () => PermissionStatus.openSnapKeySettings(),
          ),
          const Divider(height: 1),
          PermissionTile(
            icon: Icons.notifications_active,
            title: 'Notification access',
            subtitle: 'Needed to detect the Snap Key',
            granted: notificationPolicyGranted,
            onFix: notificationPolicyGranted
                ? null
                : () => PermissionStatus.openNotificationPolicySettings(),
          ),
          const Divider(height: 1),
          PermissionTile(
            icon: Icons.notifications,
            title: 'Post notifications',
            subtitle: 'Needed for the persistent "active" notification',
            granted: postNotificationsGranted,
            onFix: postNotificationsGranted
                ? null
                : () => PermissionStatus.openAppSettings(),
          ),
          const Divider(height: 1),
          PermissionTile(
            icon: Icons.layers,
            title: 'Display over other apps',
            subtitle: 'Lets actions launch directly, without a notification',
            granted: overlayGranted,
            onFix: overlayGranted
                ? null
                : () => PermissionStatus.openOverlaySettings(),
          ),
          const Divider(height: 1),
          PermissionTile(
            icon: Icons.fullscreen,
            title: 'Full screen intent access',
            subtitle: 'Fallback when "Display over other apps" is off',
            granted: fullScreenIntentGranted,
            onFix: fullScreenIntentGranted
                ? null
                : () => PermissionStatus.openFullScreenIntentSettings(),
          ),
          const Divider(height: 1),
          PermissionTile(
            icon: Icons.battery_alert,
            title: 'Battery optimization',
            subtitle: 'Exempt the app so it keeps running',
            granted: batteryOptimizationIgnored,
            onFix: batteryOptimizationIgnored
                ? null
                : () => PermissionStatus.requestBatteryOptimizationExemption(),
          ),
          const Divider(height: 1),
          PermissionTile(
            icon: Icons.battery_std,
            title: 'ColorOS background activity',
            subtitle: 'Set "Allow background activity" in app info',
            granted: false,
            showGrantedPill: false,
            actionLabel: 'Open',
            onFix: () => PermissionStatus.openAppSettings(),
          ),
          const Divider(height: 1),
          PermissionTile(
            icon: Icons.toggle_off,
            title: 'ColorOS autostart',
            subtitle: 'Allow autostart so it survives reboot',
            granted: false,
            showGrantedPill: false,
            actionLabel: 'Open',
            onFix: () => PermissionStatus.openAutostartSettings(),
          ),
        ],
      ),
    );
  }
}
