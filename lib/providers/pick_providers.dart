import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pick.dart';
import 'repository_providers.dart';
import 'cycle_providers.dart';

/// Provider for all picks in current cycle
final picksProvider = Provider<List<Pick>>((ref) {
  final repo = ref.watch(pickRepositoryProvider);
  final currentCycle = ref.watch(currentCycleProvider);
  if (currentCycle == null) return [];
  return repo.getPicksForCycle(currentCycle.id);
});

/// Provider for unevaluated picks
/// Picks that haven't been matched against a drawing result yet
final unevaluatedPicksProvider = Provider<List<Pick>>((ref) {
  final repo = ref.watch(pickRepositoryProvider);
  final currentCycle = ref.watch(currentCycleProvider);
  if (currentCycle == null) return [];
  return repo.getUnevaluatedPicks(currentCycle.id);
});

/// Provider for evaluated picks with results
final evaluatedPicksProvider = Provider<List<Pick>>((ref) {
  final repo = ref.watch(pickRepositoryProvider);
  final currentCycle = ref.watch(currentCycleProvider);
  if (currentCycle == null) return [];
  return repo.getEvaluatedPicks(currentCycle.id);
});

/// Provider for preliminary picks
/// Picks created during Phase 1 (before B₀ is locked)
final preliminaryPicksProvider = Provider<List<Pick>>((ref) {
  final picks = ref.watch(picksProvider);
  return picks.where((pick) => pick.isPreliminary).toList();
});

/// Provider for auto-generated picks
final autoPicksProvider = Provider<List<Pick>>((ref) {
  final picks = ref.watch(picksProvider);
  return picks.where((pick) => pick.isAutoPick).toList();
});

/// Provider for manual picks
final manualPicksProvider = Provider<List<Pick>>((ref) {
  final picks = ref.watch(picksProvider);
  return picks.where((pick) => !pick.isAutoPick).toList();
});

/// Provider for pick statistics
final pickStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final picks = ref.watch(picksProvider);
  final evaluated = picks.where((p) => p.matchCount != null).toList();

  if (evaluated.isEmpty) {
    return {
      'totalPicks': picks.length,
      'evaluatedPicks': 0,
      'avgMatches': 0.0,
      'bestMatch': 0,
      'powerballHits': 0,
      'winningPicks': 0,
    };
  }

  final totalMatches = evaluated.fold<int>(
    0,
    (sum, pick) => sum + (pick.matchCount ?? 0),
  );
  final powerballHits = evaluated.where((p) => p.powerballMatch == true).length;
  final winningPicks = evaluated.where((p) => (p.matchCount ?? 0) >= 3).length;
  final bestMatch = evaluated.fold<int>(
    0,
    (max, pick) => (pick.matchCount ?? 0) > max ? (pick.matchCount ?? 0) : max,
  );

  return {
    'totalPicks': picks.length,
    'evaluatedPicks': evaluated.length,
    'avgMatches': totalMatches / evaluated.length,
    'bestMatch': bestMatch,
    'powerballHits': powerballHits,
    'winningPicks': winningPicks,
  };
});

/// Provider for pick history (all cycles)
final pickHistoryProvider = Provider<List<Pick>>((ref) {
  final repo = ref.watch(pickRepositoryProvider);
  return repo.getAllPicks();
});

/// Provider for recent picks (last 10)
final recentPicksProvider = Provider<List<Pick>>((ref) {
  final picks = ref.watch(picksProvider);
  final sorted = [...picks]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted.take(10).toList();
});

/// Provider for next drawing picks
/// Picks targeting the next upcoming drawing
final nextDrawingPicksProvider = Provider<List<Pick>>((ref) {
  final picks = ref.watch(unevaluatedPicksProvider);
  if (picks.isEmpty) return [];

  // Find the earliest target draw date
  final earliestDate = picks.fold<DateTime>(
    picks.first.targetDrawDate,
    (earliest, pick) => pick.targetDrawDate.isBefore(earliest)
        ? pick.targetDrawDate
        : earliest,
  );

  // Return picks for that date
  return picks
      .where((pick) => pick.targetDrawDate == earliestDate)
      .toList();
});

/// Provider for pick performance by type
final pickPerformanceProvider = Provider<Map<String, dynamic>>((ref) {
  final picks = ref.watch(evaluatedPicksProvider);

  final autoPicks = picks.where((p) => p.isAutoPick).toList();
  final manualPicks = picks.where((p) => !p.isAutoPick).toList();

  double avgMatches(List<Pick> pickList) {
    if (pickList.isEmpty) return 0.0;
    final total = pickList.fold<int>(0, (sum, p) => sum + (p.matchCount ?? 0));
    return total / pickList.length;
  }

  return {
    'autoAvg': avgMatches(autoPicks),
    'manualAvg': avgMatches(manualPicks),
    'autoTotal': autoPicks.length,
    'manualTotal': manualPicks.length,
  };
});
