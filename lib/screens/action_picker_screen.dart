import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/installed_app.dart';
import '../models/snap_key_action.dart';
import '../services/action_channel.dart';
import '../widgets/action_picker/alarm_action_tab.dart';
import '../widgets/action_picker/app_action_tab.dart';
import '../widgets/action_picker/media_play_pause_action_tab.dart';
import '../widgets/action_picker/url_action_tab.dart';

enum _ActionTab { app, url, alarm, mediaPlayPause }

/// Tasker-style picker for the action fired when the Snap Key is pressed.
/// `ToggleTorch` was deliberately dropped from scope (design/DESIGN.md).
class ActionPickerScreen extends StatefulWidget {
  const ActionPickerScreen({super.key});

  @override
  State<ActionPickerScreen> createState() => _ActionPickerScreenState();
}

class _ActionPickerScreenState extends State<ActionPickerScreen> {
  _ActionTab _tab = _ActionTab.app;
  List<InstalledApp> _apps = const [];
  bool _loadingApps = true;
  String _search = '';
  String? _selectedPackage;
  final _urlController = TextEditingController();
  TimeOfDay? _alarmTime;
  final _alarmLabelController = TextEditingController();
  Set<int> _alarmDays = {};

  // Screen-level session cache of already-fetched icon bytes, keyed by
  // packageName, so scrolling a row out of view and back in doesn't refetch.
  final Map<String, Uint8List> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _alarmLabelController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final results = await Future.wait([
      ActionChannel.getActionConfig(),
      ActionChannel.getInstalledApps(),
    ]);
    final currentAction = results[0] as SnapKeyAction;
    final apps = results[1] as List<InstalledApp>;
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _loadingApps = false;
      switch (currentAction) {
        case OpenAppAction(:final packageName):
          _tab = _ActionTab.app;
          _selectedPackage = packageName;
        case OpenUrlAction(:final url):
          _tab = _ActionTab.url;
          _urlController.text = url;
        case SetAlarmAction(
          :final hour,
          :final minute,
          :final label,
          :final daysOfWeek,
        ):
          _tab = _ActionTab.alarm;
          _alarmTime = TimeOfDay(hour: hour, minute: minute);
          _alarmLabelController.text = label ?? '';
          _alarmDays = daysOfWeek.toSet();
        case MediaPlayPauseAction():
          _tab = _ActionTab.mediaPlayPause;
        case NoAction():
          break;
      }
    });
  }

  bool get _canSave {
    return switch (_tab) {
      _ActionTab.app => _selectedPackage != null,
      _ActionTab.url => _urlController.text.trim().isNotEmpty,
      _ActionTab.alarm => _alarmTime != null,
      _ActionTab.mediaPlayPause => true,
    };
  }

  Future<void> _save() async {
    final action = switch (_tab) {
      _ActionTab.app => OpenAppAction(_selectedPackage!),
      _ActionTab.url => OpenUrlAction(_urlController.text.trim()),
      _ActionTab.alarm => SetAlarmAction(
        hour: _alarmTime!.hour,
        minute: _alarmTime!.minute,
        label: _alarmLabelController.text.trim().isEmpty
            ? null
            : _alarmLabelController.text.trim(),
        daysOfWeek: _alarmDays.toList()..sort(),
      ),
      _ActionTab.mediaPlayPause => const MediaPlayPauseAction(),
    };
    await ActionChannel.setActionConfig(action);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _pickAlarmTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() => _alarmTime = picked);
  }

  void _onAlarmDayToggled(int day, bool selected) {
    setState(() {
      if (selected) {
        _alarmDays.add(day);
      } else {
        _alarmDays.remove(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose action'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_ActionTab>(
                segments: const [
                  ButtonSegment(
                    value: _ActionTab.app,
                    icon: Icon(Icons.apps),
                    label: Text('App'),
                  ),
                  ButtonSegment(
                    value: _ActionTab.url,
                    icon: Icon(Icons.link),
                    label: Text('URL'),
                  ),
                  ButtonSegment(
                    value: _ActionTab.alarm,
                    icon: Icon(Icons.alarm),
                    label: Text('Alarm'),
                  ),
                  ButtonSegment(
                    value: _ActionTab.mediaPlayPause,
                    icon: Icon(Icons.play_arrow),
                    label: Text('Media'),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (selection) {
                  setState(() => _tab = selection.first);
                },
              ),
            ),
          ),
          Expanded(
            child: switch (_tab) {
              _ActionTab.app => AppActionTab(
                loading: _loadingApps,
                apps: _apps,
                search: _search,
                onSearchChanged: (value) => setState(() => _search = value),
                selectedPackage: _selectedPackage,
                onSelectedChanged: (value) =>
                    setState(() => _selectedPackage = value),
                iconCache: _iconCache,
              ),
              _ActionTab.url => UrlActionTab(
                controller: _urlController,
                onChanged: () => setState(() {}),
              ),
              _ActionTab.alarm => AlarmActionTab(
                alarmTime: _alarmTime,
                onPickTime: _pickAlarmTime,
                selectedDays: _alarmDays,
                onDayToggled: _onAlarmDayToggled,
                labelController: _alarmLabelController,
              ),
              _ActionTab.mediaPlayPause => const MediaPlayPauseActionTab(),
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: const Text('Save action'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
