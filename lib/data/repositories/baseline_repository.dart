import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/baseline.dart';
import '../local/hive_service.dart';

/// Repository for Baseline data operations
/// All data is stored in Hive (local storage only)
///
/// Baseline Types:
/// - B₀ (initial): First 20 drawings, locked for cycle duration
/// - Bₙ (rolling): Last 20 drawings, recalculated every 5 drawings
/// - Bₚ (preliminary): Phase 1 baseline, updated as data collects
///
/// History Tracking:
/// - B₀: Single baseline per cycle (locked)
/// - Bₚ: Multiple snapshots during Phase 1 (optional)
/// - Bₙ: Multiple snapshots showing evolution (every 5 drawings)
class BaselineRepository {
  late final Box _box;
  static const _uuid = Uuid();

  BaselineRepository() {
    _box = HiveService.getBox(HiveService.baselinesBox);
  }

  /// Save a baseline to Hive
  Future<void> save(Baseline baseline) async {
    await _box.put(baseline.id, baseline.toJson());
  }

  /// Get a baseline by ID
  Baseline? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return Baseline.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Get all baselines, sorted by creation date descending (newest first)
  List<Baseline> getAll() {
    final baselines = _box.values
        .map((e) => Baseline.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    baselines.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return baselines;
  }

  /// Get baselines for a specific cycle
  List<Baseline> getByCycleId(String cycleId) {
    return getAll().where((b) => b.cycleId == cycleId).toList();
  }

  /// Get baselines by type
  List<Baseline> getByType(BaselineType type) {
    return getAll().where((b) => b.type == type).toList();
  }

  /// Get baselines for a specific cycle and type
  List<Baseline> getByCycleAndType(String cycleId, BaselineType type) {
    return getAll()
        .where((b) => b.cycleId == cycleId && b.type == type)
        .toList();
  }

  /// Get the initial baseline (B₀) for a cycle
  Baseline? getInitialBaseline(String cycleId) {
    final baselines = getByCycleAndType(cycleId, BaselineType.initial);
    return baselines.isEmpty ? null : baselines.first;
  }

  /// Get the latest rolling baseline (Bₙ) for a cycle
  Baseline? getLatestRollingBaseline(String cycleId) {
    final baselines = getByCycleAndType(cycleId, BaselineType.rolling);
    return baselines.isEmpty ? null : baselines.first;
  }

  /// Get the latest preliminary baseline (Bₚ) for a cycle
  Baseline? getLatestPreliminaryBaseline(String cycleId) {
    final baselines = getByCycleAndType(cycleId, BaselineType.preliminary);
    return baselines.isEmpty ? null : baselines.first;
  }

  /// Get all rolling baselines for a cycle (history)
  /// Useful for tracking baseline evolution over time
  List<Baseline> getRollingBaselineHistory(String cycleId) {
    return getByCycleAndType(cycleId, BaselineType.rolling);
  }

  /// Get all preliminary baselines for a cycle (history during Phase 1)
  List<Baseline> getPreliminaryBaselineHistory(String cycleId) {
    return getByCycleAndType(cycleId, BaselineType.preliminary);
  }

  /// Get the active baseline for analysis
  /// Returns Bₙ if available, otherwise Bₚ, otherwise B₀
  Baseline? getActiveBaseline(String cycleId) {
    // Try rolling first (Phase 2)
    var baseline = getLatestRollingBaseline(cycleId);
    if (baseline != null) return baseline;

    // Try preliminary (Phase 1)
    baseline = getLatestPreliminaryBaseline(cycleId);
    if (baseline != null) return baseline;

    // Fallback to initial
    return getInitialBaseline(cycleId);
  }

  /// Delete a baseline by ID
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Delete all baselines for a cycle
  Future<void> deleteByCycleId(String cycleId) async {
    final baselines = getByCycleId(cycleId);
    for (final baseline in baselines) {
      await delete(baseline.id);
    }
  }

  /// Delete all baselines (use with caution!)
  Future<void> deleteAll() async {
    await _box.clear();
  }

  /// Watch for changes to the baselines box
  Stream<BoxEvent> watch() {
    return _box.watch();
  }

  /// Get count of all baselines
  int getCount() {
    return _box.length;
  }

  /// Get count of baselines for a specific cycle
  int getCountByCycle(String cycleId) {
    return getByCycleId(cycleId).length;
  }

  /// Check if initial baseline exists for a cycle
  bool hasInitialBaseline(String cycleId) {
    return getInitialBaseline(cycleId) != null;
  }

  /// Calculate overlap between two baselines (percentage of shared hot numbers)
  /// Returns value between 0.0 and 100.0
  double calculateOverlap(Baseline baseline1, Baseline baseline2) {
    final set1 = Set<int>.from(baseline1.hotWhiteballs);
    final set2 = Set<int>.from(baseline2.hotWhiteballs);

    if (set1.isEmpty && set2.isEmpty) return 100.0;
    if (set1.isEmpty || set2.isEmpty) return 0.0;

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    return (intersection / union) * 100;
  }

  /// Calculate overlap between B₀ and Bₙ for a cycle
  /// Returns null if either baseline doesn't exist
  double? calculateB0BnOverlap(String cycleId) {
    final b0 = getInitialBaseline(cycleId);
    final bn = getLatestRollingBaseline(cycleId);

    if (b0 == null || bn == null) return null;

    return calculateOverlap(b0, bn);
  }

  /// Check if baselines are diverging (overlap < 50%)
  bool areDiverging(String cycleId) {
    final overlap = calculateB0BnOverlap(cycleId);
    return overlap != null && overlap < 50.0;
  }

  /// Get baseline history for a cycle (all types, chronological)
  List<Baseline> getFullHistory(String cycleId) {
    final baselines = getByCycleId(cycleId);
    baselines.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return baselines;
  }

  /// Get statistics about baselines
  Map<String, dynamic> getStatistics({String? cycleId}) {
    final baselines = cycleId != null ? getByCycleId(cycleId) : getAll();

    if (baselines.isEmpty) {
      return {
        'totalBaselines': 0,
        'initialCount': 0,
        'rollingCount': 0,
        'preliminaryCount': 0,
      };
    }

    final initial = baselines.where((b) => b.type == BaselineType.initial).length;
    final rolling = baselines.where((b) => b.type == BaselineType.rolling).length;
    final prelim = baselines.where((b) => b.type == BaselineType.preliminary).length;

    return {
      'totalBaselines': baselines.length,
      'initialCount': initial,
      'rollingCount': rolling,
      'preliminaryCount': prelim,
      'hasInitial': initial > 0,
      'hasRolling': rolling > 0,
      'hasPreliminary': prelim > 0,
    };
  }

  /// Get the most recent baseline of any type for a cycle
  Baseline? getLatest(String cycleId) {
    final baselines = getByCycleId(cycleId);
    return baselines.isEmpty ? null : baselines.first;
  }

  /// Get all baselines sorted by cycle
  Map<String, List<Baseline>> getGroupedByCycle() {
    final grouped = <String, List<Baseline>>{};
    final all = getAll();

    for (final baseline in all) {
      grouped.putIfAbsent(baseline.cycleId, () => []).add(baseline);
    }

    return grouped;
  }

  /// Create a new baseline (helper method)
  Future<Baseline> createBaseline({
    required String cycleId,
    required BaselineType type,
    required DateRange drawingRange,
    required int drawingCount,
    required Map<int, int> whiteballFreq,
    required Map<int, int> powerballFreq,
    required Map<String, int> cooccurrence,
    required List<int> hotWhiteballs,
    required List<int> coldWhiteballs,
    required List<int> neverDrawnWB,
    required List<int> hotPowerballs,
    required List<int> neverDrawnPB,
    required Statistics statistics,
    double? smoothingFactor,
  }) async {
    final baseline = Baseline(
      id: _uuid.v4(),
      cycleId: cycleId,
      type: type,
      drawingRange: drawingRange,
      drawingCount: drawingCount,
      whiteballFreq: whiteballFreq,
      powerballFreq: powerballFreq,
      cooccurrence: cooccurrence,
      hotWhiteballs: hotWhiteballs,
      coldWhiteballs: coldWhiteballs,
      neverDrawnWB: neverDrawnWB,
      hotPowerballs: hotPowerballs,
      neverDrawnPB: neverDrawnPB,
      statistics: statistics,
      smoothingFactor: smoothingFactor,
      createdAt: DateTime.now(),
    );

    await save(baseline);
    return baseline;
  }

  /// Get baselines within a date range
  List<Baseline> getByDateRange(DateTime startDate, DateTime endDate) {
    return getAll()
        .where((b) =>
            b.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
            b.createdAt.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  /// Compare evolution of rolling baselines (Bₙ history)
  /// Returns list of overlap percentages between consecutive Bₙ baselines
  List<double> getRollingBaselineEvolution(String cycleId) {
    final rolling = getRollingBaselineHistory(cycleId);
    if (rolling.length < 2) return [];

    final overlaps = <double>[];
    for (int i = 0; i < rolling.length - 1; i++) {
      overlaps.add(calculateOverlap(rolling[i], rolling[i + 1]));
    }

    return overlaps;
  }

  /// Get hot numbers that appeared in all baselines of a cycle
  /// "Consistently hot" numbers
  Set<int> getConsistentlyHotNumbers(String cycleId) {
    final baselines = getByCycleId(cycleId);
    if (baselines.isEmpty) return {};

    var commonHot = Set<int>.from(baselines.first.hotWhiteballs);
    for (final baseline in baselines.skip(1)) {
      commonHot = commonHot.intersection(Set<int>.from(baseline.hotWhiteballs));
    }

    return commonHot;
  }

  /// Get numbers that were never hot in any baseline
  /// "Consistently cold/stable" numbers
  Set<int> getNeverHotNumbers(String cycleId) {
    final baselines = getByCycleId(cycleId);
    if (baselines.isEmpty) return {};

    final allHotNumbers = <int>{};
    for (final baseline in baselines) {
      allHotNumbers.addAll(baseline.hotWhiteballs);
    }

    // All possible white ball numbers
    final allNumbers = Set<int>.from(List.generate(69, (i) => i + 1));
    return allNumbers.difference(allHotNumbers);
  }

  /// Validate baseline data integrity
  bool validateBaseline(Baseline baseline) {
    // Check frequency maps are not empty
    if (baseline.whiteballFreq.isEmpty || baseline.powerballFreq.isEmpty) {
      return false;
    }

    // Check drawing count matches
    if (baseline.drawingCount <= 0) return false;

    // Check hot numbers are in valid range
    for (final num in baseline.hotWhiteballs) {
      if (num < 1 || num > 69) return false;
    }

    for (final num in baseline.hotPowerballs) {
      if (num < 1 || num > 26) return false;
    }

    return true;
  }
}
