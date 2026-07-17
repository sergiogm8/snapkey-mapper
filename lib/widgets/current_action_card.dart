import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:snapkey_mapper/widgets/test_action_button.dart';

import '../models/snap_key_action.dart';
import '../theme/app_theme.dart';

/// Card showing the action currently configured to fire on Snap Key press,
/// with a button to open [ActionPickerScreen] and change it.
class CurrentActionCard extends StatelessWidget {
  const CurrentActionCard({
    super.key,
    required this.action,
    required this.actionIconBytes,
    required this.onChangePressed,
    required this.testAction,
  });

  final SnapKeyAction action;
  final Uint8List? actionIconBytes;
  final VoidCallback onChangePressed;
  final VoidCallback testAction;

  String _label(BuildContext context) {
    return switch (action) {
      OpenAppAction(:final packageName) => 'Opens $packageName',
      OpenUrlAction(:final url) => 'Opens $url',
      SetAlarmAction(:final hour, :final minute) =>
        'Sets alarm for ${TimeOfDay(hour: hour, minute: minute).format(context)}',
      MediaPlayPauseAction() => 'Play/Pause media',
      NoAction() => 'No action configured yet',
    };
  }

  IconData get _icon {
    return switch (action) {
      OpenAppAction() => Icons.apps,
      OpenUrlAction() => Icons.link,
      SetAlarmAction() => Icons.alarm,
      MediaPlayPauseAction() => Icons.play_arrow,
      NoAction() => Icons.help_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WHEN SNAP KEY IS PRESSED',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.tertiaryContainer,
                  backgroundImage: actionIconBytes != null
                      ? MemoryImage(actionIconBytes!)
                      : null,
                  child: actionIconBytes == null
                      ? Icon(_icon, color: colorScheme.onTertiaryContainer)
                      : null,
                ),
                const SizedBox(width: AppSpacing.row),
                Expanded(child: Text(_label(context))),
                FilledButton.tonal(
                  onPressed: onChangePressed,
                  child: const Text('Change'),
                ),
              ],
            ),
            Center(child: TestActionButton(onPressed: testAction)),
          ],
        ),
      ),
    );
  }
}
