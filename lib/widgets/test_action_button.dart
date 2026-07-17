import 'package:flutter/material.dart';

/// "Test action now" button — fires the configured action immediately
/// without needing a real Snap Key press.
class TestActionButton extends StatelessWidget {
  const TestActionButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.bolt),
          label: const Text('Test action now'),
        ),
        const SizedBox(height: 6),
        Text(
          'Fires instantly — no need to press the key',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
