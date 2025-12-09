import 'package:hive_flutter/hive_flutter.dart';
import '../../models/baseline.dart';
import '../local/hive_service.dart';

/// Repository for Baseline data operations
/// All data is stored in Hive (local storage only)
class BaselineRepository {
  late final Box _box;

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
}
