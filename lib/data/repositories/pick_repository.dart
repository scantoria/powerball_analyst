import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/pick.dart';
import '../local/hive_service.dart';

/// Repository for Pick data operations
/// All data is stored in Hive (local storage only)
///
/// Pick Evaluation:
/// - Picks start unevaluated (matchCount = null)
/// - After drawing, evaluate against results
/// - Track wins, match distribution, powerball hits
///
/// Performance Tracking:
/// - Auto-pick vs Manual pick comparison
/// - Preliminary vs Regular pick comparison
/// - Historical performance metrics
class PickRepository {
  late final Box _box;
  static const _uuid = Uuid();

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

  /// Create a new pick (helper method)
  Future<Pick> createPick({
    required String cycleId,
    required List<int> whiteBalls,
    required int powerball,
    required DateTime targetDrawDate,
    bool isAutoPick = false,
    bool isPreliminary = false,
    String? explanation,
  }) async {
    // Calculate sum and odd count
    final sumTotal = whiteBalls.reduce((a, b) => a + b);
    final oddCount = whiteBalls.where((n) => n % 2 != 0).length;

    final pick = Pick(
      id: _uuid.v4(),
      cycleId: cycleId,
      whiteBalls: List.from(whiteBalls)..sort(),
      powerball: powerball,
      targetDrawDate: targetDrawDate,
      isAutoPick: isAutoPick,
      isPreliminary: isPreliminary,
      sumTotal: sumTotal,
      oddCount: oddCount,
      explanation: explanation,
      createdAt: DateTime.now(),
    );

    await save(pick);
    return pick;
  }

  /// Get unevaluated picks for a specific cycle
  List<Pick> getUnevaluatedByCycle(String cycleId) {
    return getByCycleId(cycleId)
        .where((p) => p.evaluatedAt == null)
        .toList();
  }

  /// Get evaluated picks for a specific cycle
  List<Pick> getEvaluatedByCycle(String cycleId) {
    return getByCycleId(cycleId)
        .where((p) => p.evaluatedAt != null)
        .toList();
  }

  /// Compare auto-pick vs manual pick performance
  Map<String, dynamic> compareAutoVsManual() {
    final autoPicks = getAutoPicks().where((p) => p.evaluatedAt != null).toList();
    final manualPicks = getManualPicks().where((p) => p.evaluatedAt != null).toList();

    double avgMatches(List<Pick> picks) {
      if (picks.isEmpty) return 0.0;
      final total = picks.fold<int>(0, (sum, p) => sum + (p.matchCount ?? 0));
      return total / picks.length;
    }

    double powerballRate(List<Pick> picks) {
      if (picks.isEmpty) return 0.0;
      final hits = picks.where((p) => p.powerballMatch == true).length;
      return hits / picks.length;
    }

    return {
      'autoPickCount': autoPicks.length,
      'manualPickCount': manualPicks.length,
      'autoAvgMatches': avgMatches(autoPicks),
      'manualAvgMatches': avgMatches(manualPicks),
      'autoPowerballRate': powerballRate(autoPicks),
      'manualPowerballRate': powerballRate(manualPicks),
    };
  }

  /// Get picks by date range
  List<Pick> getByDateRange(DateTime startDate, DateTime endDate) {
    return getAll()
        .where((p) =>
            p.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
            p.createdAt.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  /// Get best performing picks (highest match counts)
  List<Pick> getTopPerformers({int limit = 10}) {
    final evaluated = getEvaluated();
    evaluated.sort((a, b) {
      final aScore = (a.matchCount ?? 0) * 10 + (a.powerballMatch == true ? 5 : 0);
      final bScore = (b.matchCount ?? 0) * 10 + (b.powerballMatch == true ? 5 : 0);
      return bScore.compareTo(aScore);
    });
    return evaluated.take(limit).toList();
  }

  /// Calculate prize tier for a pick
  /// Returns prize tier string or 'No Win'
  String getPrizeTier(Pick pick) {
    if (pick.matchCount == null) return 'Not Evaluated';

    final matches = pick.matchCount!;
    final pbMatch = pick.powerballMatch == true;

    if (matches == 5 && pbMatch) return 'Jackpot';
    if (matches == 5 && !pbMatch) return 'Match 5';
    if (matches == 4 && pbMatch) return 'Match 4 + PB';
    if (matches == 4 && !pbMatch) return 'Match 4';
    if (matches == 3 && pbMatch) return 'Match 3 + PB';
    if (matches == 3 && !pbMatch) return 'Match 3';
    if (matches == 2 && pbMatch) return 'Match 2 + PB';
    if (matches == 1 && pbMatch) return 'Match 1 + PB';
    if (matches == 0 && pbMatch) return 'PB Only';

    return 'No Win';
  }

  /// Get prize tier distribution
  Map<String, int> getPrizeTierDistribution() {
    final evaluated = getEvaluated();
    final distribution = <String, int>{};

    for (final pick in evaluated) {
      final tier = getPrizeTier(pick);
      distribution[tier] = (distribution[tier] ?? 0) + 1;
    }

    return distribution;
  }

  /// Get performance statistics by cycle
  Map<String, dynamic> getPerformanceStatsByCycle(String cycleId) {
    final picks = getByCycleId(cycleId);
    final evaluated = picks.where((p) => p.evaluatedAt != null).toList();

    if (evaluated.isEmpty) {
      return {
        'totalPicks': picks.length,
        'totalEvaluated': 0,
        'wins': 0,
        'avgMatches': 0.0,
      };
    }

    final wins = evaluated.where((p) => (p.matchCount ?? 0) > 0).length;
    final totalMatches = evaluated.fold<int>(0, (sum, p) => sum + (p.matchCount ?? 0));

    return {
      'totalPicks': picks.length,
      'totalEvaluated': evaluated.length,
      'wins': wins,
      'avgMatches': totalMatches / evaluated.length,
    };
  }

  /// Get picks targeting upcoming drawings
  List<Pick> getUpcomingPicks() {
    final now = DateTime.now();
    return getUnevaluated()
        .where((p) => p.targetDrawDate.isAfter(now))
        .toList();
  }

  /// Get picks for past drawings (missed evaluations)
  List<Pick> getOverduePicks() {
    final now = DateTime.now();
    return getUnevaluated()
        .where((p) => p.targetDrawDate.isBefore(now))
        .toList();
  }

  /// Get recently created picks (last N)
  List<Pick> getRecent({int limit = 10}) {
    final all = getAll();
    return all.take(limit).toList();
  }

  /// Get lucky numbers (most frequently picked)
  Map<int, int> getLuckyNumbers() {
    final frequency = <int, int>{};

    for (final pick in getAll()) {
      for (final number in pick.whiteBalls) {
        frequency[number] = (frequency[number] ?? 0) + 1;
      }
    }

    return Map.fromEntries(
      frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Get lucky powerball numbers
  Map<int, int> getLuckyPowerballs() {
    final frequency = <int, int>{};

    for (final pick in getAll()) {
      frequency[pick.powerball] = (frequency[pick.powerball] ?? 0) + 1;
    }

    return Map.fromEntries(
      frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Validate pick numbers
  bool validatePick(List<int> whiteBalls, int powerball) {
    // Check white balls
    if (whiteBalls.length != 5) return false;
    if (whiteBalls.any((n) => n < 1 || n > 69)) return false;
    if (whiteBalls.toSet().length != 5) return false; // No duplicates

    // Check powerball
    if (powerball < 1 || powerball > 26) return false;

    return true;
  }
}
