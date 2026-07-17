import 'package:flutter/material.dart';

/// "URL" tab of the action picker.
class UrlActionTab extends StatelessWidget {
  const UrlActionTab({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'URL',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'https://your-link.com',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          Text(
            'Opens in your default browser when triggered',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
