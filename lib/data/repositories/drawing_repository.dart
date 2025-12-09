import 'package:hive_flutter/hive_flutter.dart';
import '../../models/drawing.dart';
import '../local/hive_service.dart';

/// Repository for Drawing data operations
/// All data is stored in Hive (local storage only)
class DrawingRepository {
  late final Box _box;

  DrawingRepository() {
    _box = HiveService.getBox(HiveService.drawingsBox);
  }

  /// Save a drawing to Hive
  Future<void> save(Drawing drawing) async {
    await _box.put(drawing.id, drawing.toJson());
  }

  /// Save multiple drawings in bulk
  Future<void> saveAll(List<Drawing> drawings) async {
    final map = {for (var d in drawings) d.id: d.toJson()};
    await _box.putAll(map);
  }

  /// Get a drawing by ID
  Drawing? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return Drawing.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Get all drawings, sorted by date descending (newest first)
  List<Drawing> getAll() {
    final drawings = _box.values
        .map((e) => Drawing.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    drawings.sort((a, b) => b.drawDate.compareTo(a.drawDate));
    return drawings;
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
  }

  /// Delete all drawings (use with caution!)
  Future<void> deleteAll() async {
    await _box.clear();
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
}
