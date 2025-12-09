import 'package:hive_flutter/hive_flutter.dart';
import '../../models/cycle.dart';
import '../local/hive_service.dart';

/// Repository for Cycle data operations
/// All data is stored in Hive (local storage only)
class CycleRepository {
  late final Box _box;

  CycleRepository() {
    _box = HiveService.getBox(HiveService.cyclesBox);
  }

  /// Save a cycle to Hive
  Future<void> save(Cycle cycle) async {
    await _box.put(cycle.id, cycle.toJson());
  }

  /// Get a cycle by ID
  Cycle? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return Cycle.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Get all cycles, sorted by creation date descending (newest first)
  List<Cycle> getAll() {
    final cycles = _box.values
        .map((e) => Cycle.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    cycles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return cycles;
  }

  /// Get the current active or collecting cycle
  /// Only one cycle should be active or collecting at a time
  Cycle? getCurrentCycle() {
    return getAll().firstWhere(
      (c) => c.status == CycleStatus.collecting || c.status == CycleStatus.active,
      orElse: () => throw StateError('No active cycle found'),
    );
  }

  /// Check if there's an active or collecting cycle
  bool hasActiveCycle() {
    try {
      getCurrentCycle();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all closed cycles
  List<Cycle> getClosedCycles() {
    return getAll().where((c) => c.status == CycleStatus.closed).toList();
  }

  /// Get cycles by status
  List<Cycle> getByStatus(CycleStatus status) {
    return getAll().where((c) => c.status == status).toList();
  }

  /// Update cycle status
  Future<void> updateStatus(String cycleId, CycleStatus newStatus) async {
    final cycle = getById(cycleId);
    if (cycle == null) throw Exception('Cycle not found: $cycleId');

    final updated = cycle.copyWith(status: newStatus);
    await save(updated);
  }

  /// Close a cycle
  Future<void> closeCycle(String cycleId) async {
    final cycle = getById(cycleId);
    if (cycle == null) throw Exception('Cycle not found: $cycleId');

    final updated = cycle.copyWith(
      status: CycleStatus.closed,
      endDate: DateTime.now(),
      closedAt: DateTime.now(),
    );
    await save(updated);
  }

  /// Increment drawing count for a cycle
  Future<void> incrementDrawingCount(String cycleId) async {
    final cycle = getById(cycleId);
    if (cycle == null) throw Exception('Cycle not found: $cycleId');

    final updated = cycle.copyWith(
      drawingCount: cycle.drawingCount + 1,
    );
    await save(updated);

    // Check if we should transition from collecting to active
    if (updated.drawingCount == 20 && updated.status == CycleStatus.collecting) {
      await updateStatus(cycleId, CycleStatus.active);
    }
  }

  /// Update baseline references for a cycle
  Future<void> updateBaselineReferences({
    required String cycleId,
    String? initialBaselineId,
    String? rollingBaselineId,
    String? prelimBaselineId,
  }) async {
    final cycle = getById(cycleId);
    if (cycle == null) throw Exception('Cycle not found: $cycleId');

    final updated = cycle.copyWith(
      initialBaselineId: initialBaselineId ?? cycle.initialBaselineId,
      rollingBaselineId: rollingBaselineId ?? cycle.rollingBaselineId,
      prelimBaselineId: prelimBaselineId ?? cycle.prelimBaselineId,
    );
    await save(updated);
  }

  /// Delete a cycle by ID
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Delete all cycles (use with caution!)
  Future<void> deleteAll() async {
    await _box.clear();
  }

  /// Watch for changes to the cycles box
  Stream<BoxEvent> watch() {
    return _box.watch();
  }

  /// Get count of all cycles
  int getCount() {
    return _box.length;
  }

  /// Validate that only one cycle is active/collecting
  bool validateSingleActiveRule() {
    final activeCycles = getAll()
        .where((c) =>
            c.status == CycleStatus.collecting || c.status == CycleStatus.active)
        .toList();
    return activeCycles.length <= 1;
  }
}
