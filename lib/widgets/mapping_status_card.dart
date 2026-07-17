import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Top card on the home screen: shows whether the Snap Key mapping is on and
/// exposes the on/off switch. While the persisted intent ([serviceEnabled])
/// and the live service state ([serviceRunning]) disagree, the listener is
/// still starting up (or shutting down) — shown as a spinner so the user
/// knows when the mapping is actually ready to use.
class MappingStatusCard extends StatelessWidget {
  const MappingStatusCard({
    super.key,
    required this.serviceEnabled,
    required this.serviceRunning,
    required this.onToggle,
  });

  final bool serviceEnabled;
  final bool serviceRunning;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final mismatch = serviceEnabled != serviceRunning;
    final String subtitle;
    if (mismatch) {
      subtitle = serviceEnabled ? 'Starting listener…' : 'Stopping listener…';
    } else if (serviceEnabled) {
      subtitle = 'Ready — long-press Snap Key to fire your action';
    } else {
      subtitle = 'Turn on to start listening';
    }

    // Background reflects the target state (serviceEnabled) rather than the
    // live one — the spinner already communicates the in-between transition.
    final background = serviceEnabled
        ? AppStatusColors.active
        : AppStatusColors.inactive;
    const foreground = Colors.white;

    return Card(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: foreground.withValues(alpha: 0.2),
              child: mismatch
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: foreground,
                      ),
                    )
                  : const Icon(Icons.power_settings_new, color: foreground),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceEnabled ? 'Mapping is on' : 'Mapping is off',
                    style: textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: foreground.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: serviceEnabled,
              onChanged: onToggle,
              activeThumbColor: foreground,
              activeTrackColor: foreground.withValues(alpha: 0.4),
              inactiveThumbColor: foreground,
              inactiveTrackColor: foreground.withValues(alpha: 0.4),
              trackOutlineColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
