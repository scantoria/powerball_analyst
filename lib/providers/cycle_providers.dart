import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cycle.dart';
import 'repository_providers.dart';

/// Provider for all cycles
final cyclesProvider = Provider<List<Cycle>>((ref) {
  final repo = ref.watch(cycleRepositoryProvider);
  return repo.getAll();
});

/// Provider for current active/collecting cycle
final currentCycleProvider = Provider<Cycle?>((ref) {
  final repo = ref.watch(cycleRepositoryProvider);
  try {
    return repo.getCurrentCycle();
  } catch (e) {
    return null;
  }
});

/// Provider for cycle phase (collecting or active)
final cyclePhaseProvider = Provider<CycleStatus?>((ref) {
  final cycle = ref.watch(currentCycleProvider);
  return cycle?.status;
});

/// Provider for checking if we're in Phase 1 (collecting baseline)
final isPhase1Provider = Provider<bool>((ref) {
  final status = ref.watch(cyclePhaseProvider);
  return status == CycleStatus.collecting;
});

/// Provider for checking if we're in Phase 2 (active analysis)
final isPhase2Provider = Provider<bool>((ref) {
  final status = ref.watch(cyclePhaseProvider);
  return status == CycleStatus.active;
});

/// Provider for closed cycles
final closedCyclesProvider = Provider<List<Cycle>>((ref) {
  final repo = ref.watch(cycleRepositoryProvider);
  return repo.getClosedCycles();
});

/// Provider for current cycle's drawing count
final currentCycleDrawingCountProvider = Provider<int>((ref) {
  final cycle = ref.watch(currentCycleProvider);
  return cycle?.drawingCount ?? 0;
});
