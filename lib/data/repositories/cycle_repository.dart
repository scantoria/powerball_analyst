import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/cycle.dart';
import '../local/hive_service.dart';

/// Repository for Cycle data operations
/// All data is stored in Hive (local storage only)
///
/// Cycle Lifecycle:
/// 1. collecting (Phase 1): Gathering first 20 drawings for B₀
/// 2. active (Phase 2): B₀ locked, Bₙ calculated every 5 drawings
/// 3. closed: Cycle ended, archived for history
///
/// Business Rules:
/// - Only ONE cycle can be active or collecting at a time
/// - Automatic transition from collecting → active at 20 drawings
/// - Closing a cycle sets endDate and closedAt timestamps
class CycleRepository {
  late final Box _box;
  static const _uuid = Uuid();

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

  /// Create a new cycle
  /// Throws if there's already an active/collecting cycle
  Future<Cycle> createCycle({String? name, String? notes}) async {
    if (hasActiveCycle()) {
      throw StateError('Cannot create new cycle: An active cycle already exists');
    }

    final cycle = Cycle(
      id: _uuid.v4(),
      name: name,
      startDate: DateTime.now(),
      status: CycleStatus.collecting,
      createdAt: DateTime.now(),
      notes: notes,
    );

    await save(cycle);
    return cycle;
  }

  /// Transition cycle from collecting to active
  /// Called when cycle reaches 20 drawings
  Future<void> transitionToActive(String cycleId) async {
    final cycle = getById(cycleId);
    if (cycle == null) throw Exception('Cycle not found: $cycleId');

    if (cycle.status != CycleStatus.collecting) {
      throw StateError('Can only transition from collecting to active');
    }

    if (cycle.drawingCount < 20) {
      throw StateError('Cycle must have 20 drawings to transition to active');
    }

    final updated = cycle.copyWith(status: CycleStatus.active);
    await save(updated);
  }

  /// Close current cycle and optionally create a new one
  /// Returns the new cycle if created
  Future<Cycle?> closeCurrentAndCreateNew({
    String? reason,
    bool createNew = true,
  }) async {
    try {
      final current = getCurrentCycle();
      if (current != null) {
        await closeCycle(current.id);
      }

      if (createNew) {
        return await createCycle(
          name: 'Cycle ${getCount() + 1}',
          notes: reason != null ? 'Previous cycle closed: $reason' : null,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to close and create cycle: $e');
    }
  }

  /// Update cycle name
  Future<void> updateName(String cycleId, String name) async {
    final cycle = getById(cycleId);
    if (cycle == null) throw Exception('Cycle not found: $cycleId');

    final updated = cycle.copyWith(name: name);
    await save(updated);
  }

  /// Update cycle notes
  Future<void> updateNotes(String cycleId, String notes) async {
    final cycle = getById(cycleId);
    if (cycle == null) throw Exception('Cycle not found: $cycleId');

    final updated = cycle.copyWith(notes: notes);
    await save(updated);
  }

  /// Get cycle statistics
  Map<String, dynamic> getStatistics() {
    final all = getAll();
    if (all.isEmpty) {
      return {
        'totalCycles': 0,
        'activeCycles': 0,
        'closedCycles': 0,
        'collectingCycles': 0,
      };
    }

    final active = all.where((c) => c.status == CycleStatus.active).length;
    final closed = all.where((c) => c.status == CycleStatus.closed).length;
    final collecting = all.where((c) => c.status == CycleStatus.collecting).length;

    return {
      'totalCycles': all.length,
      'activeCycles': active,
      'closedCycles': closed,
      'collectingCycles': collecting,
      'hasActiveCycle': hasActiveCycle(),
      'isValid': validateSingleActiveRule(),
    };
  }

  /// Get cycle duration in days
  int? getCycleDuration(String cycleId) {
    final cycle = getById(cycleId);
    if (cycle == null) return null;

    final endDate = cycle.endDate ?? DateTime.now();
    return endDate.difference(cycle.startDate).inDays;
  }

  /// Get average cycle duration (for closed cycles)
  double? getAverageCycleDuration() {
    final closed = getClosedCycles();
    if (closed.isEmpty) return null;

    final durations = closed
        .where((c) => c.endDate != null)
        .map((c) => c.endDate!.difference(c.startDate).inDays)
        .toList();

    if (durations.isEmpty) return null;

    return durations.reduce((a, b) => a + b) / durations.length;
  }

  /// Check if cycle is in Phase 1 (collecting)
  bool isPhase1(String cycleId) {
    final cycle = getById(cycleId);
    return cycle?.status == CycleStatus.collecting;
  }

  /// Check if cycle is in Phase 2 (active)
  bool isPhase2(String cycleId) {
    final cycle = getById(cycleId);
    return cycle?.status == CycleStatus.active;
  }

  /// Get cycle progress (0.0 to 1.0) for Phase 1
  /// Returns null if not in Phase 1 or doesn't exist
  double? getPhase1Progress(String cycleId) {
    final cycle = getById(cycleId);
    if (cycle == null || cycle.status != CycleStatus.collecting) return null;

    return (cycle.drawingCount / 20).clamp(0.0, 1.0);
  }

  /// Check if cycle is ready to transition to active
  bool isReadyForActive(String cycleId) {
    final cycle = getById(cycleId);
    if (cycle == null) return false;

    return cycle.status == CycleStatus.collecting &&
        cycle.drawingCount >= 20 &&
        cycle.initialBaselineId != null;
  }
}
