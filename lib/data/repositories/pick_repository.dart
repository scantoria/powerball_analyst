import 'package:hive_flutter/hive_flutter.dart';
import '../../models/pick.dart';
import '../local/hive_service.dart';

/// Repository for Pick data operations
/// All data is stored in Hive (local storage only)
class PickRepository {
  late final Box _box;

  PickRepository() {
    _box = HiveService.getBox(HiveService.picksBox);
  }

  /// Save a pick to Hive
  Future<void> save(Pick pick) async {
    await _box.put(pick.id, pick.toJson());
  }

  /// Get a pick by ID
  Pick? getById(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    return Pick.fromJson(Map<String, dynamic>.from(json as Map));
  }

  /// Get all picks, sorted by creation date descending (newest first)
  List<Pick> getAll() {
    final picks = _box.values
        .map((e) => Pick.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    picks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return picks;
  }

  /// Get picks for a specific cycle
  List<Pick> getByCycleId(String cycleId) {
    return getAll().where((p) => p.cycleId == cycleId).toList();
  }

  /// Get picks for a specific target drawing date
  List<Pick> getByTargetDate(DateTime targetDate) {
    return getAll()
        .where((p) =>
            p.targetDrawDate.year == targetDate.year &&
            p.targetDrawDate.month == targetDate.month &&
            p.targetDrawDate.day == targetDate.day)
        .toList();
  }

  /// Get picks that haven't been evaluated yet
  List<Pick> getUnevaluated() {
    return getAll().where((p) => p.evaluatedAt == null).toList();
  }

  /// Get picks that have been evaluated
  List<Pick> getEvaluated() {
    return getAll().where((p) => p.evaluatedAt != null).toList();
  }

  /// Get auto-picks only
  List<Pick> getAutoPicks() {
    return getAll().where((p) => p.isAutoPick).toList();
  }

  /// Get manual picks only
  List<Pick> getManualPicks() {
    return getAll().where((p) => !p.isAutoPick).toList();
  }

  /// Get preliminary picks (created during Phase 1)
  List<Pick> getPreliminaryPicks() {
    return getAll().where((p) => p.isPreliminary).toList();
  }

  /// Get picks by match count
  List<Pick> getByMatchCount(int matchCount) {
    return getAll().where((p) => p.matchCount == matchCount).toList();
  }

  /// Get winning picks (matchCount > 0)
  List<Pick> getWinningPicks() {
    return getAll().where((p) => p.matchCount != null && p.matchCount! > 0).toList();
  }

  /// Evaluate a pick against a drawing result
  /// Updates matchCount and powerballMatch
  Future<void> evaluatePick({
    required String pickId,
    required List<int> winningWhiteBalls,
    required int winningPowerball,
  }) async {
    final pick = getById(pickId);
    if (pick == null) throw Exception('Pick not found: $pickId');

    // Count white ball matches
    int matches = 0;
    for (final number in pick.whiteBalls) {
      if (winningWhiteBalls.contains(number)) {
        matches++;
      }
    }

    // Check powerball match
    final pbMatch = pick.powerball == winningPowerball;

    // Update pick
    final updated = pick.copyWith(
      matchCount: matches,
      powerballMatch: pbMatch,
      evaluatedAt: DateTime.now(),
    );

    await save(updated);
  }

  /// Get performance statistics for all evaluated picks
  Map<String, dynamic> getPerformanceStats() {
    final evaluated = getEvaluated();
    if (evaluated.isEmpty) {
      return {
        'totalPicks': 0,
        'totalEvaluated': 0,
        'wins': 0,
        'winRate': 0.0,
        'avgMatches': 0.0,
        'powerballHitRate': 0.0,
        'matchDistribution': <int, int>{},
      };
    }

    final wins = getWinningPicks().length;
    final totalMatches = evaluated
        .map((p) => p.matchCount ?? 0)
        .reduce((a, b) => a + b);
    final powerballHits = evaluated
        .where((p) => p.powerballMatch == true)
        .length;

    // Match count distribution
    final distribution = <int, int>{};
    for (var i = 0; i <= 5; i++) {
      distribution[i] = getByMatchCount(i).length;
    }

    return {
      'totalPicks': getAll().length,
      'totalEvaluated': evaluated.length,
      'wins': wins,
      'winRate': wins / evaluated.length,
      'avgMatches': totalMatches / evaluated.length,
      'powerballHitRate': powerballHits / evaluated.length,
      'matchDistribution': distribution,
    };
  }

  /// Delete a pick by ID
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Delete all picks for a cycle
  Future<void> deleteByCycleId(String cycleId) async {
    final picks = getByCycleId(cycleId);
    for (final pick in picks) {
      await delete(pick.id);
    }
  }

  /// Delete all picks (use with caution!)
  Future<void> deleteAll() async {
    await _box.clear();
  }

  /// Watch for changes to the picks box
  Stream<BoxEvent> watch() {
    return _box.watch();
  }

  /// Get count of all picks
  int getCount() {
    return _box.length;
  }

  /// Get count of picks for a specific cycle
  int getCountByCycle(String cycleId) {
    return getByCycleId(cycleId).length;
  }
}
