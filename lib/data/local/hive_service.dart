import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing Hive local storage
///
/// Hive is the PRIMARY and ONLY data persistence layer for this app.
///
/// Data Flow: NY Open Data API → Hive → UI
///
/// No Firebase, no cloud sync. All data is stored locally on device.
/// Backup strategy: CSV/JSON export for manual backup.
///
/// Storage Strategy:
/// - Models are stored as JSON Maps using Freezed's built-in serialization
/// - No custom Hive type adapters needed - we leverage existing toJson/fromJson
/// - Keys are model IDs (String), values are Map<String, dynamic>
class HiveService {
  // Box names
  static const String drawingsBox = 'drawings';
  static const String cyclesBox = 'cycles';
  static const String baselinesBox = 'baselines';
  static const String picksBox = 'picks';
  static const String shiftsBox = 'shifts';
  static const String settingsBox = 'settings';
  static const String metadataBox = 'metadata';

  /// Initialize Hive and open all boxes
  ///
  /// Models are stored as JSON Maps, so no type adapter registration needed.
  /// We use the Freezed-generated toJson/fromJson methods for serialization.
  static Future<void> init() async {
    await Hive.initFlutter();

    // Open boxes for all data types
    // Boxes store Map<String, dynamic> representing JSON-serialized models
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

  // ========== CRUD Helper Methods ==========
  //
  // These methods provide type-safe operations for storing/retrieving models.
  // Models must have toJson() and fromJson() methods (provided by Freezed).

  /// Save a model to a box using its ID as the key
  ///
  /// Example: await HiveService.put(drawingsBox, drawing.id, drawing.toJson());
  static Future<void> put(
    String boxName,
    String key,
    Map<String, dynamic> value,
  ) async {
    final box = getBox(boxName);
    await box.put(key, value);
  }

  /// Get a model from a box by ID
  ///
  /// Returns null if not found.
  /// Example: final json = HiveService.get(drawingsBox, 'drawing_20250101');
  static Map<String, dynamic>? get(String boxName, String key) {
    final box = getBox(boxName);
    final value = box.get(key);
    return value != null ? Map<String, dynamic>.from(value) : null;
  }

  /// Delete a model from a box by ID
  static Future<void> delete(String boxName, String key) async {
    final box = getBox(boxName);
    await box.delete(key);
  }

  /// Get all models from a box as a list of JSON Maps
  ///
  /// Example:
  /// ```dart
  /// final jsonList = HiveService.getAll(drawingsBox);
  /// final drawings = jsonList.map((json) => Drawing.fromJson(json)).toList();
  /// ```
  static List<Map<String, dynamic>> getAll(String boxName) {
    final box = getBox(boxName);
    return box.values
        .map((value) => Map<String, dynamic>.from(value))
        .toList();
  }

  /// Get all models from a box as a Map keyed by ID
  ///
  /// Example: final drawingsMap = HiveService.getAllAsMap(drawingsBox);
  static Map<String, Map<String, dynamic>> getAllAsMap(String boxName) {
    final box = getBox(boxName);
    return Map.fromEntries(
      box.toMap().entries.map(
            (e) => MapEntry(
              e.key.toString(),
              Map<String, dynamic>.from(e.value),
            ),
          ),
    );
  }

  /// Save multiple models to a box
  ///
  /// Example:
  /// ```dart
  /// await HiveService.putAll(
  ///   drawingsBox,
  ///   {drawing.id: drawing.toJson(), drawing2.id: drawing2.toJson()},
  /// );
  /// ```
  static Future<void> putAll(
    String boxName,
    Map<String, Map<String, dynamic>> entries,
  ) async {
    final box = getBox(boxName);
    await box.putAll(entries);
  }

  /// Check if a key exists in a box
  static bool containsKey(String boxName, String key) {
    final box = getBox(boxName);
    return box.containsKey(key);
  }

  /// Get all keys from a box
  static List<String> getKeys(String boxName) {
    final box = getBox(boxName);
    return box.keys.map((key) => key.toString()).toList();
  }

  /// Watch a specific key for changes
  ///
  /// Returns a Stream that emits the new JSON value whenever it changes.
  static Stream<Map<String, dynamic>?> watch(String boxName, String key) {
    final box = getBox(boxName);
    return box.watch(key: key).map((event) {
      final value = event.value;
      return value != null ? Map<String, dynamic>.from(value) : null;
    });
  }

  /// Watch all values in a box
  ///
  /// Returns a Stream that emits whenever any value in the box changes.
  static Stream<List<Map<String, dynamic>>> watchAll(String boxName) {
    final box = getBox(boxName);
    return box.watch().map((_) => getAll(boxName));
  }
}
