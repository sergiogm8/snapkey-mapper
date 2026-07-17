import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/installed_app.dart';
import 'app_icon_avatar.dart';

/// "App" tab of the action picker: searchable list of installed apps, radio-
/// selectable. [search] and [selectedPackage] are owned by the parent screen
/// so they survive switching to another tab and back.
class AppActionTab extends StatelessWidget {
  const AppActionTab({
    super.key,
    required this.loading,
    required this.apps,
    required this.search,
    required this.onSearchChanged,
    required this.selectedPackage,
    required this.onSelectedChanged,
    required this.iconCache,
  });

  final bool loading;
  final List<InstalledApp> apps;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final String? selectedPackage;
  final ValueChanged<String?> onSelectedChanged;
  final Map<String, Uint8List> iconCache;

  List<InstalledApp> get _filteredApps {
    if (search.isEmpty) return apps;
    final query = search.toLowerCase();
    return apps
        .where(
          (app) =>
              app.label.toLowerCase().contains(query) ||
              app.packageName.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final filteredApps = _filteredApps;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search apps',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RadioGroup<String>(
              groupValue: selectedPackage,
              onChanged: onSelectedChanged,
              child: ListView.builder(
                itemCount: filteredApps.length,
                itemBuilder: (context, index) {
                  final app = filteredApps[index];
                  final selected = app.packageName == selectedPackage;
                  return ListTile(
                    selected: selected,
                    leading: AppIconAvatar(
                      packageName: app.packageName,
                      label: app.label,
                      iconCache: iconCache,
                    ),
                    title: Text(app.label),
                    trailing: Radio<String>(value: app.packageName),
                    onTap: () => onSelectedChanged(app.packageName),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
