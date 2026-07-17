/// Mirrors the Kotlin `ActionConfig` sealed model
/// (android/.../ActionConfig.kt) — keep the JSON shape identical on both
/// sides: `{"type": "open_app"|"open_url"|"set_alarm"|"media_play_pause"|
/// "none", ...}`.
///
/// A `ToggleTorch` case was deliberately dropped from scope, see CLAUDE.md.
sealed class SnapKeyAction {
  const SnapKeyAction();

  Map<String, dynamic> toJson();

  static SnapKeyAction fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'open_app':
        return OpenAppAction(json['packageName'] as String);
      case 'open_url':
        return OpenUrlAction(json['url'] as String);
      case 'set_alarm':
        return SetAlarmAction(
          hour: json['hour'] as int,
          minute: json['minute'] as int,
          label: json['label'] as String?,
          daysOfWeek:
              (json['daysOfWeek'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              const [],
        );
      case 'media_play_pause':
        return const MediaPlayPauseAction();
      default:
        return const NoAction();
    }
  }
}

class OpenAppAction extends SnapKeyAction {
  const OpenAppAction(this.packageName);

  final String packageName;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'open_app',
    'packageName': packageName,
  };
}

class OpenUrlAction extends SnapKeyAction {
  const OpenUrlAction(this.url);

  final String url;

  @override
  Map<String, dynamic> toJson() => {'type': 'open_url', 'url': url};
}

/// Opens the system clock app's "set alarm" screen, pre-filled via the
/// implicit `AlarmClock.ACTION_SET_ALARM` intent. [daysOfWeek] uses
/// `java.util.Calendar` day-of-week constants (1=Sunday..7=Saturday, matching
/// `AlarmClock.EXTRA_DAYS`'s expected format) — empty means a one-time alarm.
class SetAlarmAction extends SnapKeyAction {
  const SetAlarmAction({
    required this.hour,
    required this.minute,
    this.label,
    this.daysOfWeek = const [],
  });

  final int hour;
  final int minute;
  final String? label;
  final List<int> daysOfWeek;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'set_alarm',
    'hour': hour,
    'minute': minute,
    if (label != null) 'label': label,
    'daysOfWeek': daysOfWeek,
  };
}

/// Sends a media play/pause key event via `AudioManager` — no target app to
/// configure, it controls whatever currently holds media session focus.
class MediaPlayPauseAction extends SnapKeyAction {
  const MediaPlayPauseAction();

  @override
  Map<String, dynamic> toJson() => {'type': 'media_play_pause'};
}

class NoAction extends SnapKeyAction {
  const NoAction();

  @override
  Map<String, dynamic> toJson() => {'type': 'none'};
}
