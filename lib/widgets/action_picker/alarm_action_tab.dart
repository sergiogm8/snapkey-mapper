import 'package:flutter/material.dart';

/// `daysOfWeek` uses java.util.Calendar day-of-week constants, matching
/// `SetAlarmAction.daysOfWeek` / `AlarmClock.EXTRA_DAYS`'s expected format.
const List<MapEntry<int, String>> _weekDays = [
  MapEntry(2, 'Mon'),
  MapEntry(3, 'Tue'),
  MapEntry(4, 'Wed'),
  MapEntry(5, 'Thu'),
  MapEntry(6, 'Fri'),
  MapEntry(7, 'Sat'),
  MapEntry(1, 'Sun'),
];

/// "Alarm" tab of the action picker.
class AlarmActionTab extends StatelessWidget {
  const AlarmActionTab({
    super.key,
    required this.alarmTime,
    required this.onPickTime,
    required this.selectedDays,
    required this.onDayToggled,
    required this.labelController,
  });

  final TimeOfDay? alarmTime;
  final VoidCallback onPickTime;
  final Set<int> selectedDays;
  final void Function(int day, bool selected) onDayToggled;
  final TextEditingController labelController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TIME',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPickTime,
            icon: const Icon(Icons.access_time),
            label: Text(
              alarmTime == null ? 'Pick a time' : alarmTime!.format(context),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'REPEAT',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _weekDays.map((entry) {
              final selected = selectedDays.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (value) => onDayToggled(entry.key, value),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            selectedDays.isEmpty
                ? 'One-time alarm (no days selected)'
                : 'Repeats on selected days',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          Text(
            'LABEL (OPTIONAL)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: labelController,
            decoration: const InputDecoration(
              hintText: 'Wake up',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
