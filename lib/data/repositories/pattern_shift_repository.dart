import 'package:hive_flutter/hive_flutter.dart';
import '../../models/pattern_shift.dart';
import '../local/hive_service.dart';

/// Repository for PatternShift data operations
/// All data is stored in Hive (local storage only)
///
/// Pattern Shifts:
/// - Detect significant pattern changes that may indicate cycle transitions
/// - 5 trigger types: longTermDrift, shortTermSurge, baselineDivergence, correlationBreakdown, newDominance
/// - Severity levels: low, medium, high
/// - Can be dismissed by user or trigger new cycle creation
class PatternShiftRepository {
  late final Box _box;

  PatternShiftRepository() {
    _box = HiveService.getBox(HiveService.shiftsBox);
  }

  /// Save a pattern shift to Hive
  Future<void> save(PatternShift shift) async {
    await _box.put(shift.id, shift.toJson());
  }

  /// Get a pattern shift by ID
  PatternShift? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return PatternShift.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Get all pattern shifts, sorted by detection date descending (newest first)
  List<PatternShift> getAll() {
    final shifts = _box.values
        .map((e) =>
            PatternShift.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    shifts.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return shifts;
  }

  /// Get pattern shifts for a specific cycle
  List<PatternShift> getByCycleId(String cycleId) {
    return getAll().where((s) => s.cycleId == cycleId).toList();
  }

  /// Get active (non-dismissed) pattern shifts for a cycle
  List<PatternShift> getActive(String cycleId) {
    return getByCycleId(cycleId)
        .where((s) => !s.isDismissed)
        .toList();
  }

  /// Get dismissed pattern shifts for a cycle
  List<PatternShift> getDismissed(String cycleId) {
    return getByCycleId(cycleId)
        .where((s) => s.isDismissed)
        .toList();
  }

  /// Get pattern shifts by trigger type
  List<PatternShift> getByTriggerType(ShiftTrigger triggerType) {
    return getAll()
        .where((s) => s.triggerType == triggerType)
        .toList();
  }

  /// Get pattern shifts by severity
  List<PatternShift> getBySeverity(ShiftSeverity severity) {
    return getAll()
        .where((s) => s.severity == severity)
        .toList();
  }

  /// Get high severity shifts for a cycle
  List<PatternShift> getHighSeverity(String cycleId) {
    return getByCycleId(cycleId)
        .where((s) => s.severity == ShiftSeverity.high)
        .toList();
  }

  /// Dismiss a pattern shift
  Future<void> dismiss(String id) async {
    final shift = getById(id);
    if (shift == null) return;

    final updated = shift.copyWith(
      isDismissed: true,
      dismissedAt: DateTime.now(),
    );
    await save(updated);
  }

  /// Mark a pattern shift as having triggered a new cycle
  Future<void> markAsTriggeredNewCycle(String id) async {
    final shift = getById(id);
    if (shift == null) return;

    final updated = shift.copyWith(triggeredNewCycle: true);
    await save(updated);
  }

  /// Delete a pattern shift
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Delete all pattern shifts
  Future<void> deleteAll() async {
    await _box.clear();
  }

  /// Delete all pattern shifts for a specific cycle
  Future<void> deleteByCycleId(String cycleId) async {
    final shifts = getByCycleId(cycleId);
    for (final shift in shifts) {
      await delete(shift.id);
    }
  }

  /// Get count of active shifts for a cycle
  int getActiveCount(String cycleId) {
    return getActive(cycleId).length;
  }

  /// Get pattern shift statistics
  Map<String, dynamic> getStatistics() {
    final all = getAll();
    final active = all.where((s) => !s.isDismissed).length;
    final dismissed = all.where((s) => s.isDismissed).length;
    final triggeredCycles = all.where((s) => s.triggeredNewCycle).length;

    final byTrigger = <ShiftTrigger, int>{};
    for (final trigger in ShiftTrigger.values) {
      byTrigger[trigger] = all.where((s) => s.triggerType == trigger).length;
    }

    final bySeverity = <ShiftSeverity, int>{};
    for (final severity in ShiftSeverity.values) {
      bySeverity[severity] =
          all.where((s) => s.severity == severity).length;
    }

    return {
      'total': all.length,
      'active': active,
      'dismissed': dismissed,
      'triggeredNewCycles': triggeredCycles,
      'byTrigger': byTrigger,
      'bySeverity': bySeverity,
    };
  }

  /// Get recent pattern shifts (last N)
  List<PatternShift> getRecent(int limit) {
    final all = getAll();
    return all.take(limit).toList();
  }

  /// Check if pattern shifts exist for a cycle
  bool hasCycleShifts(String cycleId) {
    return getByCycleId(cycleId).isNotEmpty;
  }

  /// Get count of pattern shifts
  int getCount() {
    return _box.length;
  }

  /// Watch for changes to the pattern shifts box
  Stream<BoxEvent> watch() {
    return _box.watch();
  }
}
