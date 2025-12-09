import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing Hive local storage
///
/// Hive is the PRIMARY and ONLY data persistence layer for this app.
///
/// Data Flow: NY Open Data API → Hive → UI
///
/// No Firebase, no cloud sync. All data is stored locally on device.
/// Backup strategy: CSV/JSON export for manual backup.
class HiveService {
  // Box names
  static const String drawingsBox = 'drawingsBox';
  static const String cyclesBox = 'cyclesBox';
  static const String baselinesBox = 'baselinesBox';
  static const String picksBox = 'picksBox';
  static const String shiftsBox = 'shiftsBox';
  static const String settingsBox = 'settingsBox';
  static const String metadataBox = 'metadataBox';

  /// Initialize Hive and register type adapters
  static Future<void> init() async {
    await Hive.initFlutter();

    // TODO: Register type adapters after code generation with hive_generator
    // These adapters will be auto-generated from the model classes
    //
    // Hive.registerAdapter(DrawingAdapter());
    // Hive.registerAdapter(CycleAdapter());
    // Hive.registerAdapter(BaselineAdapter());
    // Hive.registerAdapter(PickAdapter());
    // Hive.registerAdapter(PatternShiftAdapter());
    // Hive.registerAdapter(SettingsAdapter());
    // Hive.registerAdapter(CycleStatusAdapter());
    // Hive.registerAdapter(BaselineTypeAdapter());
    // Hive.registerAdapter(ShiftTriggerAdapter());
    // Hive.registerAdapter(SmoothingLevelAdapter());
    // Hive.registerAdapter(SensitivityAdapter());
    // Hive.registerAdapter(DisplayModeAdapter());

    // Open boxes for all data types
    await Future.wait([
      Hive.openBox(drawingsBox),
      Hive.openBox(cyclesBox),
      Hive.openBox(baselinesBox),
      Hive.openBox(picksBox),
      Hive.openBox(shiftsBox),
      Hive.openBox(settingsBox),
      Hive.openBox(metadataBox),
    ]);
  }

  /// Get a specific box by name
  static Box getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception('Box $boxName is not open. Call HiveService.init() first.');
    }
    return Hive.box(boxName);
  }

  /// Close all boxes
  static Future<void> closeAll() async {
    await Hive.close();
  }

  /// Clear all data (for testing or reset)
  static Future<void> clearAll() async {
    await Future.wait([
      Hive.box(drawingsBox).clear(),
      Hive.box(cyclesBox).clear(),
      Hive.box(baselinesBox).clear(),
      Hive.box(picksBox).clear(),
      Hive.box(shiftsBox).clear(),
      Hive.box(settingsBox).clear(),
      Hive.box(metadataBox).clear(),
    ]);
  }

  /// Delete specific box
  static Future<void> deleteBox(String boxName) async {
    await Hive.deleteBoxFromDisk(boxName);
  }

  /// Export all data to JSON for backup
  static Map<String, dynamic> exportAllToJson() {
    return {
      'drawings': Hive.box(drawingsBox).toMap(),
      'cycles': Hive.box(cyclesBox).toMap(),
      'baselines': Hive.box(baselinesBox).toMap(),
      'picks': Hive.box(picksBox).toMap(),
      'shifts': Hive.box(shiftsBox).toMap(),
      'settings': Hive.box(settingsBox).toMap(),
      'metadata': Hive.box(metadataBox).toMap(),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Get storage statistics
  static Map<String, int> getStorageStats() {
    return {
      'drawings': Hive.box(drawingsBox).length,
      'cycles': Hive.box(cyclesBox).length,
      'baselines': Hive.box(baselinesBox).length,
      'picks': Hive.box(picksBox).length,
      'shifts': Hive.box(shiftsBox).length,
      'settings': Hive.box(settingsBox).length,
      'metadata': Hive.box(metadataBox).length,
    };
  }
}
