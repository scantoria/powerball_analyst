import 'package:hive_flutter/hive_flutter.dart';
import '../../models/settings.dart';
import '../local/hive_service.dart';

/// Repository for Settings data operations
/// All data is stored in Hive (local storage only)
///
/// Settings:
/// - Single user preferences object (not a collection)
/// - Stored with fixed key 'user_settings'
/// - Returns default Settings if none exist
class SettingsRepository {
  late final Box _box;
  static const String _settingsKey = 'user_settings';

  SettingsRepository() {
    _box = HiveService.getBox(HiveService.settingsBox);
  }

  /// Get user settings
  /// Returns default Settings if none exist
  Settings getSettings() {
    final json = _box.get(_settingsKey);
    if (json == null) {
      return const Settings(); // Return default settings
    }
    return Settings.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Update user settings
  /// Saves the entire Settings object
  Future<void> updateSettings(Settings settings) async {
    await _box.put(_settingsKey, settings.toJson());
  }

  /// Update smoothing factor
  Future<void> updateSmoothingFactor(SmoothingLevel smoothing) async {
    final current = getSettings();
    final updated = current.copyWith(smoothingFactor: smoothing);
    await updateSettings(updated);
  }

  /// Update shift sensitivity
  Future<void> updateShiftSensitivity(Sensitivity sensitivity, {double? customValue}) async {
    final current = getSettings();
    final updated = current.copyWith(
      shiftSensitivity: sensitivity,
      customSensitivity: customValue,
    );
    await updateSettings(updated);
  }

  /// Update display mode
  Future<void> updateDisplayMode(DisplayMode mode) async {
    final current = getSettings();
    final updated = current.copyWith(displayMode: mode);
    await updateSettings(updated);
  }

  /// Update dark mode
  Future<void> updateDarkMode(bool enabled) async {
    final current = getSettings();
    final updated = current.copyWith(darkMode: enabled);
    await updateSettings(updated);
  }

  /// Update notifications
  Future<void> updateNotifications(bool enabled) async {
    final current = getSettings();
    final updated = current.copyWith(notifications: enabled);
    await updateSettings(updated);
  }

  /// Update auto-sync
  Future<void> updateAutoSync(bool enabled) async {
    final current = getSettings();
    final updated = current.copyWith(autoSync: enabled);
    await updateSettings(updated);
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncAt(DateTime timestamp) async {
    final current = getSettings();
    final updated = current.copyWith(lastSyncAt: timestamp);
    await updateSettings(updated);
  }

  /// Update export preferences
  Future<void> updateIncludeBaselineInExport(bool include) async {
    final current = getSettings();
    final updated = current.copyWith(includeBaselineInExport: include);
    await updateSettings(updated);
  }

  /// Reset settings to defaults
  Future<void> resetToDefaults() async {
    await updateSettings(const Settings());
  }

  /// Delete all settings
  Future<void> delete() async {
    await _box.delete(_settingsKey);
  }

  /// Check if settings exist
  bool exists() {
    return _box.containsKey(_settingsKey);
  }

  /// Watch for settings changes
  Stream<BoxEvent> watch() {
    return _box.watch(key: _settingsKey);
  }
}
