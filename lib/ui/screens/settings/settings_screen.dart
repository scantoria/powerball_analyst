import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/settings_providers.dart';
import '../../../models/settings.dart';

/// Settings screen - app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Algorithm Settings'),
            subtitle: const Text('Configure smoothing and sensitivity'),
            leading: const Icon(Icons.tune),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: settings.darkMode,
            onChanged: (_) => notifier.toggleDarkMode(),
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            title: const Text('Display Mode'),
            subtitle: Text(settings.displayMode.name),
            leading: const Icon(Icons.visibility),
            trailing: DropdownButton<DisplayMode>(
              value: settings.displayMode,
              onChanged: (mode) {
                if (mode != null) notifier.updateDisplayMode(mode);
              },
              items: DisplayMode.values
                  .map((mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode.name),
                      ))
                  .toList(),
            ),
          ),
          ListTile(
            title: const Text('Smoothing Factor'),
            subtitle: Text(settings.smoothingFactor.name),
            leading: const Icon(Icons.waves),
            trailing: DropdownButton<SmoothingLevel>(
              value: settings.smoothingFactor,
              onChanged: (level) {
                if (level != null) notifier.updateSmoothingFactor(level);
              },
              items: SmoothingLevel.values
                  .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(level.name),
                      ))
                  .toList(),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Auto-Sync'),
            subtitle: const Text('Automatically fetch new drawings'),
            value: settings.autoSync,
            onChanged: (_) => notifier.toggleAutoSync(),
            secondary: const Icon(Icons.sync),
          ),
        ],
      ),
    );
  }
}
