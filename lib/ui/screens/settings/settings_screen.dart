import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../providers/settings_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/drawing_providers.dart';
import '../../../models/settings.dart';
import '../../../core/constants/app_colors.dart';

/// Settings screen - app configuration
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final drawingCount = ref.watch(drawingCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: settings.darkMode,
            onChanged: (_) => notifier.toggleDarkMode(),
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            title: const Text('Display Mode'),
            subtitle: Text(_getDisplayModeLabel(settings.displayMode)),
            leading: const Icon(Icons.visibility),
            trailing: DropdownButton<DisplayMode>(
              value: settings.displayMode,
              onChanged: (mode) {
                if (mode != null) notifier.updateDisplayMode(mode);
              },
              items: DisplayMode.values
                  .map((mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(_getDisplayModeLabel(mode)),
                      ))
                  .toList(),
            ),
          ),
          const Divider(),

          // Analysis Section
          _buildSectionHeader('Analysis'),
          ListTile(
            title: const Text('Smoothing Factor'),
            subtitle: Text(_getSmoothingLabel(settings.smoothingFactor)),
            leading: const Icon(Icons.waves),
            trailing: DropdownButton<SmoothingLevel>(
              value: settings.smoothingFactor,
              onChanged: (level) {
                if (level != null) notifier.updateSmoothingFactor(level);
              },
              items: SmoothingLevel.values
                  .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text(_getSmoothingLabel(level)),
                      ))
                  .toList(),
            ),
          ),
          const Divider(),

          // Data & Sync Section
          _buildSectionHeader('Data & Sync'),
          SwitchListTile(
            title: const Text('Auto-Sync'),
            subtitle: const Text('Automatically fetch new drawings'),
            value: settings.autoSync,
            onChanged: (_) => notifier.toggleAutoSync(),
            secondary: const Icon(Icons.sync),
          ),
          ListTile(
            title: const Text('Sync Now'),
            subtitle: const Text('Manually sync latest drawings'),
            leading: const Icon(Icons.cloud_download),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _syncNow,
          ),
          ListTile(
            title: const Text('Data Storage'),
            subtitle: Text('$drawingCount drawings stored'),
            leading: const Icon(Icons.storage),
          ),
          const Divider(),

          // Danger Zone
          _buildSectionHeader('Danger Zone'),
          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all cycles, picks, and baselines'),
            leading: const Icon(Icons.delete_forever, color: AppColors.errorRed),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showClearDataDialog,
          ),
          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('App Version'),
            subtitle: Text(_packageInfo?.version ?? 'Loading...'),
            leading: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Build Number'),
            subtitle: Text(_packageInfo?.buildNumber ?? 'Loading...'),
            leading: const Icon(Icons.tag),
          ),
          ListTile(
            title: const Text('About Powerball Analyst'),
            subtitle: const Text('Pattern analysis for NY Powerball'),
            leading: const Icon(Icons.help_outline),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showAboutDialog,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _getDisplayModeLabel(DisplayMode mode) {
    switch (mode) {
      case DisplayMode.compact:
        return 'Compact';
      case DisplayMode.comfortable:
        return 'Comfortable';
      case DisplayMode.detailed:
        return 'Detailed';
    }
  }

  String _getSmoothingLabel(SmoothingLevel level) {
    switch (level) {
      case SmoothingLevel.none:
        return 'None (Raw data)';
      case SmoothingLevel.low:
        return 'Low';
      case SmoothingLevel.medium:
        return 'Medium';
      case SmoothingLevel.high:
        return 'High';
    }
  }

  void _syncNow() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Syncing data...'),
          ],
        ),
      ),
    );

    ref.invalidate(syncStatusProvider);
    ref.invalidate(drawingsProvider);

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync complete!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all cycles, baselines, picks, and drawings. This action cannot be undone.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            onPressed: () async {
              try {
                final drawingRepo = ref.read(drawingRepositoryProvider);
                final cycleRepo = ref.read(cycleRepositoryProvider);
                final baselineRepo = ref.read(baselineRepositoryProvider);
                final pickRepo = ref.read(pickRepositoryProvider);

                await drawingRepo.deleteAll();
                await cycleRepo.deleteAll();
                await baselineRepo.deleteAll();
                await pickRepo.deleteAll();

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared successfully'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing data: $e'),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Powerball Analyst',
      applicationVersion: _packageInfo?.version ?? '1.0.0',
      applicationIcon: const Icon(Icons.analytics, size: 48, color: AppColors.primaryBlue),
      children: [
        const SizedBox(height: 16),
        const Text(
          'A pattern analysis tool for NY Powerball lottery drawings.',
        ),
        const SizedBox(height: 8),
        const Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• Real-time data sync from NY Open Data'),
        const Text('• Statistical baseline analysis'),
        const Text('• Frequency heat maps'),
        const Text('• Number picking tools'),
        const Text('• Historical tracking'),
        const SizedBox(height: 8),
        const Text(
          'Data source: NY Open Data API',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}
