import 'package:flutter/material.dart';

import '../models/trigger_log_entry.dart';
import '../theme/app_theme.dart';

/// "Recent activity" card: the native-written trigger log, newest first, or
/// an empty-state hint when nothing has fired yet.
class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({super.key, required this.log});

  final List<TriggerLogEntry> log;

  static String _relativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (log.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Text('No activity yet — try "Test action now" above.'),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          for (final entry in log)
            ListTile(
              leading: Icon(
                entry.success ? Icons.check_circle : Icons.error,
                color: entry.success
                    ? colorScheme.secondary
                    : colorScheme.error,
                size: 20,
              ),
              title: Text(entry.actionLabel, style: textTheme.bodyMedium),
              subtitle: entry.errorMessage != null
                  ? Text(entry.errorMessage!)
                  : null,
              trailing: Text(
                _relativeTime(entry.dateTime),
                style: textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
