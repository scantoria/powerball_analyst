import 'package:hive_flutter/hive_flutter.dart';
import '../../models/drawing.dart';
import '../local/hive_service.dart';

/// Repository for Drawing data operations
/// All data is stored in Hive (local storage only)
///
/// Data Flow: API → DrawingRepository → Hive
///
/// Performance Notes:
/// - getAll() loads and sorts all drawings - use sparingly
/// - Use date-specific queries for better performance
/// - Batch operations (saveAll) are optimized for bulk updates
class DrawingRepository {
  late final Box _box;
  List<Drawing>? _cachedDrawings;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  DrawingRepository() {
    _box = HiveService.getBox(HiveService.drawingsBox);
  }

  /// Clear internal cache
  void _clearCache() {
    _cachedDrawings = null;
    _cacheTimestamp = null;
  }

  /// Check if cache is valid
  bool get _isCacheValid {
    if (_cachedDrawings == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < _cacheDuration;
  }

  /// Save a drawing to Hive
  Future<void> save(Drawing drawing) async {
    await _box.put(drawing.id, drawing.toJson());
    _clearCache();
  }

  /// Save multiple drawings in bulk (optimized for sync operations)
  Future<void> saveAll(List<Drawing> drawings) async {
    if (drawings.isEmpty) return;
    final map = {for (var d in drawings) d.id: d.toJson()};
    await _box.putAll(map);
    _clearCache();
  }

  /// Get a drawing by ID
  Drawing? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return Drawing.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Get all drawings, sorted by date descending (newest first)
  /// Uses internal caching to improve performance
  List<Drawing> getAll() {
    if (_isCacheValid) {
      return List.from(_cachedDrawings!);
    }

    final drawings = _box.values
        .map((e) => Drawing.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    drawings.sort((a, b) => b.drawDate.compareTo(a.drawDate));

    _cachedDrawings = drawings;
    _cacheTimestamp = DateTime.now();

    return List.from(drawings);
  }

  /// Get drawings within a date range
  List<Drawing> getByDateRange(DateTime startDate, DateTime endDate) {
    return getAll()
        .where((d) =>
            d.drawDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            d.drawDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  /// Get latest N drawings
  List<Drawing> getLatest(int limit) {
    final all = getAll();
    return all.take(limit).toList();
  }

  /// Get the most recent drawing
  Drawing? getLatestDrawing() {
    final latest = getLatest(1);
    return latest.isEmpty ? null : latest.first;
  }

  /// Get drawings since a specific date
  List<Drawing> getSince(DateTime sinceDate) {
    return getAll()
        .where((d) => d.drawDate.isAfter(sinceDate))
        .toList();
  }

  /// Get count of all drawings
  int getCount() {
    return _box.length;
  }

  /// Check if a drawing exists by ID
  bool exists(String id) {
    return _box.containsKey(id);
  }

  /// Delete a drawing by ID
  Future<void> delete(String id) async {
    await _box.delete(id);
    _clearCache();
  }

  /// Delete all drawings (use with caution!)
  Future<void> deleteAll() async {
    await _box.clear();
    _clearCache();
  }

  /// Delete drawings older than a specific date
  Future<int> deleteOlderThan(DateTime date) async {
    final toDelete = getAll()
        .where((d) => d.drawDate.isBefore(date))
        .map((d) => d.id)
        .toList();

    for (final id in toDelete) {
      await _box.delete(id);
    }
    _clearCache();
    return toDelete.length;
  }

  /// Watch for changes to the drawings box
  /// Returns a stream that emits on any change
  Stream<BoxEvent> watch() {
    return _box.watch();
  }

  /// Get drawings for a specific cycle (by date range)
  List<Drawing> getForCycle(DateTime cycleStartDate, DateTime? cycleEndDate) {
    final endDate = cycleEndDate ?? DateTime.now();
    return getByDateRange(cycleStartDate, endDate);
  }

  /// Get the date of the earliest drawing in storage
  DateTime? getEarliestDrawingDate() {
    if (_box.isEmpty) return null;
    final all = getAll();
    return all.isEmpty ? null : all.last.drawDate;
  }

  /// Get the date of the latest drawing in storage
  DateTime? getLatestDrawingDate() {
    if (_box.isEmpty) return null;
    final latest = getLatestDrawing();
    return latest?.drawDate;
  }

  /// Get paginated drawings
  /// Returns a subset of drawings for pagination
  List<Drawing> getPaginated({required int page, required int pageSize}) {
    final all = getAll();
    final startIndex = page * pageSize;
    if (startIndex >= all.length) return [];

    final endIndex = (startIndex + pageSize).clamp(0, all.length);
    return all.sublist(startIndex, endIndex);
  }

  /// Get drawings by year
  List<Drawing> getByYear(int year) {
    return getAll()
        .where((d) => d.drawDate.year == year)
        .toList();
  }

  /// Get drawings by month and year
  List<Drawing> getByMonth(int year, int month) {
    return getAll()
        .where((d) => d.drawDate.year == year && d.drawDate.month == month)
        .toList();
  }

  /// Get statistics about stored drawings
  Map<String, dynamic> getStatistics() {
    if (_box.isEmpty) {
      return {
        'totalDrawings': 0,
        'earliestDate': null,
        'latestDate': null,
        'dateRange': null,
      };
    }

    final all = getAll();
    final earliest = all.last.drawDate;
    final latest = all.first.drawDate;
    final daysDiff = latest.difference(earliest).inDays;

    return {
      'totalDrawings': all.length,
      'earliestDate': earliest,
      'latestDate': latest,
      'dateRange': daysDiff,
      'cacheStatus': _isCacheValid ? 'valid' : 'expired',
    };
  }

  /// Check if we need to sync (no drawings or outdated data)
  bool needsSync({Duration maxAge = const Duration(days: 7)}) {
    if (_box.isEmpty) return true;

    final latestDate = getLatestDrawingDate();
    if (latestDate == null) return true;

    return DateTime.now().difference(latestDate) > maxAge;
  }

  /// Find gaps in drawing dates (missing drawings)
  /// Returns list of dates where drawings might be missing
  List<DateTime> findGaps() {
    final all = getAll();
    if (all.length < 2) return [];

    final gaps = <DateTime>[];
    for (int i = 0; i < all.length - 1; i++) {
      final current = all[i].drawDate;
      final next = all[i + 1].drawDate;
      final daysBetween = current.difference(next).inDays;

      // Powerball draws typically 3x per week (Mon, Wed, Sat)
      // Gap of more than 4 days might indicate missing data
      if (daysBetween > 4) {
        gaps.add(next.add(Duration(days: 1)));
      }
    }
    return gaps;
  }

  /// Get IDs of all stored drawings (for sync comparison)
  Set<String> getAllIds() {
    return _box.keys.map((k) => k.toString()).toSet();
  }

  /// Upsert (update or insert) drawings
  /// Only saves if drawing doesn't exist or has changed
  Future<int> upsertAll(List<Drawing> drawings) async {
    if (drawings.isEmpty) return 0;

    int updated = 0;
    final updates = <String, Map<String, dynamic>>{};

    for (final drawing in drawings) {
      final existing = getById(drawing.id);
      // Add if doesn't exist, or if data differs
      if (existing == null || existing != drawing) {
        updates[drawing.id] = drawing.toJson();
        updated++;
      }
    }

    if (updates.isNotEmpty) {
      await _box.putAll(updates);
      _clearCache();
    }

    return updated;
  }
}
