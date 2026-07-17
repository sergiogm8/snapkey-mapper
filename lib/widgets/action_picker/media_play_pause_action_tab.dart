import 'package:flutter/material.dart';

/// "Media" tab of the action picker — no configuration, just an explainer.
class MediaPlayPauseActionTab extends StatelessWidget {
  const MediaPlayPauseActionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Play/Pause media',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Sends a play/pause command to whatever app currently holds '
            'media focus (e.g. Spotify, YouTube Music) — no app to pick, it '
            'just toggles playback.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
