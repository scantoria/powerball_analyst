import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings.dart';
import '../data/local/hive_service.dart';

/// Provider for app settings
/// Settings are stored in Hive settingsBox
class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() : super(const Settings()) {
    _loadSettings();
  }

  /// Load settings from Hive
  Future<void> _loadSettings() async {
    final box = HiveService.getBox(HiveService.settingsBox);
    final json = box.get('settings');
    if (json != null) {
      state = Settings.fromJson(Map<String, dynamic>.from(json as Map));
    }
  }

  /// Save settings to Hive
  Future<void> _saveSettings() async {
    final box = HiveService.getBox(HiveService.settingsBox);
    await box.put('settings', state.toJson());
  }

  /// Update smoothing factor
  Future<void> updateSmoothingFactor(SmoothingLevel level) async {
    state = state.copyWith(smoothingFactor: level);
    await _saveSettings();
  }

  /// Update shift sensitivity
  Future<void> updateShiftSensitivity(Sensitivity sensitivity) async {
    state = state.copyWith(shiftSensitivity: sensitivity);
    await _saveSettings();
  }

  /// Update custom sensitivity threshold
  Future<void> updateCustomSensitivity(double threshold) async {
    state = state.copyWith(
      shiftSensitivity: Sensitivity.custom,
      customSensitivity: threshold,
    );
    await _saveSettings();
  }

  /// Update display mode
  Future<void> updateDisplayMode(DisplayMode mode) async {
    state = state.copyWith(displayMode: mode);
    await _saveSettings();
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    state = state.copyWith(darkMode: !state.darkMode);
    await _saveSettings();
  }

  /// Toggle notifications
  Future<void> toggleNotifications() async {
    state = state.copyWith(notifications: !state.notifications);
    await _saveSettings();
  }

  /// Toggle auto-sync
  Future<void> toggleAutoSync() async {
    state = state.copyWith(autoSync: !state.autoSync);
    await _saveSettings();
  }

  /// Toggle baseline export
  Future<void> toggleBaselineExport() async {
    state = state.copyWith(
      includeBaselineInExport: !state.includeBaselineInExport,
    );
    await _saveSettings();
  }

  /// Update last sync timestamp
  Future<void> updateLastSync(DateTime timestamp) async {
    state = state.copyWith(lastSyncAt: timestamp);
    await _saveSettings();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});

/// Convenient providers for specific settings
final darkModeProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).darkMode;
});

final displayModeProvider = Provider<DisplayMode>((ref) {
  return ref.watch(settingsProvider).displayMode;
});

final smoothingFactorProvider = Provider<SmoothingLevel>((ref) {
  return ref.watch(settingsProvider).smoothingFactor;
});

final shiftSensitivityProvider = Provider<Sensitivity>((ref) {
  return ref.watch(settingsProvider).shiftSensitivity;
});
