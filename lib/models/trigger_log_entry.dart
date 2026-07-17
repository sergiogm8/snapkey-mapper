/// One row from the native trigger log (android/.../TriggerLogStore.kt).
class TriggerLogEntry {
  const TriggerLogEntry({
    required this.timestamp,
    required this.actionLabel,
    required this.success,
    this.errorMessage,
  });

  factory TriggerLogEntry.fromMap(Map<Object?, Object?> map) {
    return TriggerLogEntry(
      timestamp: map['timestamp'] as int,
      actionLabel: map['actionLabel'] as String,
      success: map['success'] as bool,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  final int timestamp;
  final String actionLabel;
  final bool success;
  final String? errorMessage;

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}
