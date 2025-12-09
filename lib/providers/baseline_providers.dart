import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/baseline.dart';
import 'repository_providers.dart';
import 'cycle_providers.dart';

/// Provider for all baselines in current cycle
final baselinesProvider = Provider<List<Baseline>>((ref) {
  final repo = ref.watch(baselineRepositoryProvider);
  final currentCycle = ref.watch(currentCycleProvider);
  if (currentCycle == null) return [];
  return repo.getBaselinesForCycle(currentCycle.id);
});

/// Provider for initial baseline (B₀)
final initialBaselineProvider = Provider<Baseline?>((ref) {
  final currentCycle = ref.watch(currentCycleProvider);
  if (currentCycle == null || currentCycle.initialBaselineId == null) {
    return null;
  }
  final repo = ref.watch(baselineRepositoryProvider);
  return repo.getBaseline(currentCycle.initialBaselineId!);
});

/// Provider for rolling baseline (Bₙ)
final rollingBaselineProvider = Provider<Baseline?>((ref) {
  final currentCycle = ref.watch(currentCycleProvider);
  if (currentCycle == null || currentCycle.rollingBaselineId == null) {
    return null;
  }
  final repo = ref.watch(baselineRepositoryProvider);
  return repo.getBaseline(currentCycle.rollingBaselineId!);
});

/// Provider for preliminary baseline (Bₚ)
/// Only available during Phase 1 (collecting)
final preliminaryBaselineProvider = Provider<Baseline?>((ref) {
  final isPhase1 = ref.watch(isPhase1Provider);
  if (!isPhase1) return null;

  final currentCycle = ref.watch(currentCycleProvider);
  if (currentCycle == null || currentCycle.prelimBaselineId == null) {
    return null;
  }

  final repo = ref.watch(baselineRepositoryProvider);
  return repo.getBaseline(currentCycle.prelimBaselineId!);
});

/// Provider for active baseline
/// Returns Bₚ during Phase 1, Bₙ during Phase 2
final activeBaselineProvider = Provider<Baseline?>((ref) {
  final isPhase1 = ref.watch(isPhase1Provider);
  if (isPhase1) {
    return ref.watch(preliminaryBaselineProvider);
  }
  return ref.watch(rollingBaselineProvider);
});

/// Provider for baseline history
/// Returns all baselines sorted by creation date
final baselineHistoryProvider = Provider<List<Baseline>>((ref) {
  final repo = ref.watch(baselineRepositoryProvider);
  return repo.getAllBaselines();
});

/// Provider for overlap score between B₀ and Bₙ
/// Calculates percentage of shared hot numbers
final overlapScoreProvider = Provider<double?>((ref) {
  final b0 = ref.watch(initialBaselineProvider);
  final bn = ref.watch(rollingBaselineProvider);

  if (b0 == null || bn == null) return null;

  final b0Set = Set<int>.from(b0.hotWhiteballs);
  final bnSet = Set<int>.from(bn.hotWhiteballs);

  final intersection = b0Set.intersection(bnSet).length;
  final union = b0Set.union(bnSet).length;

  if (union == 0) return 0.0;
  return (intersection / union) * 100;
});

/// Provider for baseline divergence status
/// Returns true if overlap < 50%
final baselineDivergenceProvider = Provider<bool>((ref) {
  final overlap = ref.watch(overlapScoreProvider);
  if (overlap == null) return false;
  return overlap < 50.0;
});

/// Provider for baseline comparison data
/// Used by Baseline Comparison screen
final baselineComparisonProvider = Provider<Map<String, dynamic>>((ref) {
  final b0 = ref.watch(initialBaselineProvider);
  final bn = ref.watch(rollingBaselineProvider);
  final overlap = ref.watch(overlapScoreProvider);

  return {
    'b0': b0,
    'bn': bn,
    'overlapScore': overlap,
    'isDiverged': overlap != null && overlap < 50.0,
  };
});
