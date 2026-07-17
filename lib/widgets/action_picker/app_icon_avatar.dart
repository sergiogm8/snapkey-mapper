import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/action_channel.dart';

/// Lazily fetches and shows a single app's real icon, falling back to a
/// tinted initial-letter avatar while pending or on failure. [iconCache] is
/// owned by the parent screen state so icons survive rows scrolling out of
/// and back into view.
class AppIconAvatar extends StatefulWidget {
  const AppIconAvatar({
    super.key,
    required this.packageName,
    required this.label,
    required this.iconCache,
  });

  final String packageName;
  final String label;
  final Map<String, Uint8List> iconCache;

  @override
  State<AppIconAvatar> createState() => _AppIconAvatarState();
}

class _AppIconAvatarState extends State<AppIconAvatar> {
  Uint8List? _iconBytes;

  @override
  void initState() {
    super.initState();
    _iconBytes = widget.iconCache[widget.packageName];
    if (_iconBytes == null) {
      _fetchIcon();
    }
  }

  Future<void> _fetchIcon() async {
    Uint8List? bytes;
    try {
      bytes = await ActionChannel.getAppIcon(widget.packageName);
    } catch (_) {
      bytes = null;
    }
    if (bytes == null) return;
    widget.iconCache[widget.packageName] = bytes;
    if (!mounted) return;
    setState(() => _iconBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bytes = _iconBytes;
    return CircleAvatar(
      backgroundColor: colorScheme.tertiaryContainer,
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes == null
          ? Text(
              widget.label.isNotEmpty ? widget.label[0].toUpperCase() : '?',
              style: TextStyle(color: colorScheme.onTertiaryContainer),
            )
          : null,
    );
  }
}
