import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:snapkey_mapper/widgets/kofi_button.dart';

import '../models/snap_key_action.dart';
import '../models/trigger_log_entry.dart';
import '../services/action_channel.dart';
import '../services/permission_status.dart';
import '../theme/app_theme.dart';
import '../widgets/current_action_card.dart';
import '../widgets/mapping_status_card.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/setup_checklist_card.dart';
import 'action_picker_screen.dart';

/// Status screen: permission checklist, service on/off toggle, "test action
/// now" button, recent-trigger log. See design/DESIGN.md for the visual spec
/// this implements.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SnapKeyAction _currentAction = const NoAction();
  bool _serviceEnabled = false;
  bool _serviceRunning = false;
  bool _notificationPolicyGranted = false;
  bool _postNotificationsGranted = false;
  bool _overlayGranted = false;
  bool _fullScreenIntentGranted = false;
  bool _batteryOptimizationIgnored = false;
  List<TriggerLogEntry> _log = const [];
  Timer? _refreshTimer;

  // Lazily-fetched icon for the currently configured OpenAppAction, keyed by
  // packageName so a 3s _refreshAll() poll doesn't refetch it every time when
  // the configured action hasn't actually changed.
  String? _actionIconPackage;
  Uint8List? _actionIconBytes;

  @override
  void initState() {
    super.initState();
    _refreshAll();
    // Service state and trigger log are driven by the native side and can
    // change from a real Snap Key press while this screen is open — poll
    // instead of relying only on pull-to-refresh or the test button.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshAll(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    final results = await Future.wait([
      ActionChannel.getActionConfig(),
      ActionChannel.isServiceEnabled(),
      ActionChannel.isServiceRunning(),
      PermissionStatus.isNotificationPolicyGranted(),
      PermissionStatus.isPostNotificationsGranted(),
      PermissionStatus.isOverlayGranted(),
      PermissionStatus.isFullScreenIntentGranted(),
      PermissionStatus.isBatteryOptimizationIgnored(),
      ActionChannel.getTriggerLog(),
    ]);
    if (!mounted) return;
    setState(() {
      _currentAction = results[0] as SnapKeyAction;
      _serviceEnabled = results[1] as bool;
      _serviceRunning = results[2] as bool;
      _notificationPolicyGranted = results[3] as bool;
      _postNotificationsGranted = results[4] as bool;
      _overlayGranted = results[5] as bool;
      _fullScreenIntentGranted = results[6] as bool;
      _batteryOptimizationIgnored = results[7] as bool;
      _log = results[8] as List<TriggerLogEntry>;
    });
    _refreshActionIcon();
  }

  Future<void> _refreshActionIcon() async {
    final action = _currentAction;
    if (action is! OpenAppAction) {
      if (_actionIconPackage != null) {
        setState(() {
          _actionIconPackage = null;
          _actionIconBytes = null;
        });
      }
      return;
    }
    if (action.packageName == _actionIconPackage) return;
    _actionIconPackage = action.packageName;
    Uint8List? bytes;
    try {
      bytes = await ActionChannel.getAppIcon(action.packageName);
    } catch (_) {
      bytes = null;
    }
    if (!mounted || action.packageName != _actionIconPackage) return;
    setState(() => _actionIconBytes = bytes);
  }

  Future<void> _toggleService(bool value) async {
    if (value) {
      await ActionChannel.startService();
    } else {
      await ActionChannel.stopService();
    }
    await _refreshAll();
    // The service's live isRunning flag flips a moment after start/stop
    // returns (onCreate/onDestroy) — follow up quickly so the "starting"
    // spinner resolves as soon as it's ready, without waiting for the 3s poll.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _refreshAll();
    });
  }

  Future<void> _testTrigger() async {
    final result = await ActionChannel.testTrigger();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? result.actionLabel
              : 'Failed: ${result.actionLabel} '
                    '(${result.errorMessage ?? "unknown error"})',
        ),
      ),
    );
    await _refreshAll();
  }

  Future<void> _openActionPicker() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ActionPickerScreen()));
    await _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.bolt,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: const Text("SnapKey Mapper"),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            MappingStatusCard(
              serviceEnabled: _serviceEnabled,
              serviceRunning: _serviceRunning,
              onToggle: _toggleService,
            ),
            const SizedBox(height: AppSpacing.md),
            CurrentActionCard(
              action: _currentAction,
              actionIconBytes: _actionIconBytes,
              onChangePressed: _openActionPicker,
              testAction: _testTrigger,
            ),
            const SizedBox(height: AppSpacing.md),
            const KofiButton(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'SETUP CHECKLIST',
              style: textTheme.labelSmall?.copyWith(letterSpacing: 0.4),
            ),
            const SizedBox(height: 8),
            SetupChecklistCard(
              notificationPolicyGranted: _notificationPolicyGranted,
              postNotificationsGranted: _postNotificationsGranted,
              overlayGranted: _overlayGranted,
              fullScreenIntentGranted: _fullScreenIntentGranted,
              batteryOptimizationIgnored: _batteryOptimizationIgnored,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'RECENT ACTIVITY',
              style: textTheme.labelSmall?.copyWith(letterSpacing: 0.4),
            ),
            const SizedBox(height: 8),
            RecentActivityCard(log: _log),
          ],
        ),
      ),
    );
  }
}
