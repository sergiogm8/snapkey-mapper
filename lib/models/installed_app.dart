/// One entry from the native `getInstalledApps` query. Carries no icon bytes
/// — icons are fetched lazily per row via `ActionChannel.getAppIcon`, see
/// `_AppIconAvatar` in `action_picker_screen.dart`.
class InstalledApp {
  const InstalledApp({required this.packageName, required this.label});

  factory InstalledApp.fromMap(Map<Object?, Object?> map) {
    return InstalledApp(
      packageName: map['packageName'] as String,
      label: map['label'] as String,
    );
  }

  final String packageName;
  final String label;
}
