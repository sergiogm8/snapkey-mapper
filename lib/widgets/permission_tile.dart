import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Reusable checklist row: leading status icon, two-line label, and a
/// trailing pill — either a neutral "Granted" pill or a tappable "Fix" one.
/// Matches the "Setup checklist" card rows in design/DESIGN.md. Pass
/// `onFix: null` and `granted: false` for a row with no known status (e.g.
/// ColorOS autostart, which has no queryable state) to show a plain action
/// button without implying a granted/not-granted judgement.
class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.granted = false,
    this.showGrantedPill = true,
    this.actionLabel = 'Fix',
    this.onFix,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;

  /// Whether an unconditional "Granted" pill should show when [granted] is
  /// true. Set false for rows with no queryable granted/denied state (only an
  /// action), like ColorOS autostart.
  final bool showGrantedPill;
  final String actionLabel;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: granted ? AppStatusColors.active : null),
      title: Text(title),
      subtitle: Text(subtitle),
      // onFix is only ever passed when something still needs the user's
      // attention, so it's always styled with the "inactive/needs action"
      // color, regardless of [granted].
      trailing: onFix != null
          ? FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: AppStatusColors.inactiveContainer,
                foregroundColor: AppStatusColors.onInactiveContainer,
              ),
              onPressed: onFix,
              child: Text(actionLabel),
            )
          : (granted && showGrantedPill
                ? Chip(
                    label: const Text('Granted'),
                    backgroundColor: AppStatusColors.activeContainer,
                    labelStyle: const TextStyle(
                      color: AppStatusColors.onActiveContainer,
                    ),
                    side: BorderSide.none,
                  )
                : null),
    );
  }
}
