import '../../models/drawing.dart';
import '../../models/cycle.dart';
import '../../models/baseline.dart';
import '../../models/settings.dart';
import '../../data/repositories/drawing_repository.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../data/repositories/baseline_repository.dart';
import '../../data/repositories/pattern_shift_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../analysis/baseline_calculator.dart';
import '../analysis/pattern_shift_detector.dart';

/// Orchestrates cycle lifecycle, drawing additions, and baseline calculations
///
/// This service centralizes the business logic for:
/// - Processing new drawings added to a cycle
/// - Triggering baseline calculations at correct intervals
/// - Managing Phase 1→2 transition at 20 drawings
/// - Detecting and saving pattern shifts
///
/// Architecture Pattern: Orchestration Service
/// - Separates business logic from UI components
/// - Provides single source of truth for cycle operations
/// - Makes testing easier with dependency injection
class CycleOrchestrationService {
  final DrawingRepository drawingRepo;
  final CycleRepository cycleRepo;
  final BaselineRepository baselineRepo;
  final PatternShiftRepository shiftRepo;
  final BaselineCalculator baselineCalc;
  final PatternShiftDetector shiftDetector;
  final SettingsRepository settingsRepo;

  CycleOrchestrationService({
    required this.drawingRepo,
    required this.cycleRepo,
    required this.baselineRepo,
    required this.shiftRepo,
    required this.baselineCalc,
    required this.shiftDetector,
    required this.settingsRepo,
  });

  /// Called after new drawings are synced from API
  /// Processes each drawing and triggers baseline calculations
  ///
  /// Flow:
  /// 1. Get current cycle
  /// 2. Sort drawings chronologically
  /// 3. Process each drawing sequentially
  Future<void> onDrawingsAdded(List<Drawing> newDrawings) async {
    if (newDrawings.isEmpty) return;

    // Get current cycle
    final currentCycle = cycleRepo.getCurrentCycle();
    if (currentCycle == null) {
      print('No current cycle - skipping drawing processing');
      return;
    }

    // Sort drawings by date (oldest first) to process chronologically
    final sortedDrawings = List<Drawing>.from(newDrawings)
      ..sort((a, b) => a.drawDate.compareTo(b.drawDate));

    print('Processing ${sortedDrawings.length} drawings for cycle ${currentCycle.id}');

    // Process each drawing sequentially
    for (final drawing in sortedDrawings) {
      await _processDrawing(drawing, currentCycle);
    }

    print('Finished processing drawings');
  }

  /// Process single drawing addition
  ///
  /// Logic by phase:
  /// - Phase 1 (1-19): Update Bₚ (preliminary baseline)
  /// - Exactly 20: Create B₀ and first Bₙ, transition to Phase 2
  /// - Phase 2 (>20): Update Bₙ every 5 drawings, detect shifts
  Future<void> _processDrawing(Drawing drawing, Cycle cycle) async {
    try {
      // Increment drawing count
      await cycleRepo.incrementDrawingCount(cycle.id);

      // Get updated cycle with new count
      final updatedCycle = cycleRepo.getById(cycle.id);
      if (updatedCycle == null) {
        print('Error: Cycle ${cycle.id} not found after increment');
        return;
      }

      final count = updatedCycle.drawingCount;
      print('Drawing count for cycle ${cycle.id}: $count');

      // Phase 1: Collecting (1-19 drawings)
      if (count < 20 && updatedCycle.status == CycleStatus.collecting) {
        print('Phase 1: Updating preliminary baseline (count=$count)');
        await _updatePreliminaryBaseline(updatedCycle);
      }

      // Phase 1→2 Transition: Exactly 20 drawings
      else if (count == 20 && updatedCycle.status == CycleStatus.collecting) {
        print('Phase 1→2 Transition: Creating initial baseline (count=20)');
        await _createInitialBaseline(updatedCycle);
      }

      // Phase 2: Active (>20 drawings)
      else if (count > 20 && updatedCycle.status == CycleStatus.active) {
        if (baselineCalc.shouldRecalculateRolling(count)) {
          print('Phase 2: Updating rolling baseline (count=$count)');
          await _updateRollingBaseline(updatedCycle);
        } else {
          print('Phase 2: No baseline update needed (count=$count)');
        }
      }
    } catch (e) {
      print('Error processing drawing ${drawing.id}: $e');
      // Continue processing other drawings
    }
  }

  /// Create/update preliminary baseline (Phase 1, 1-19 drawings)
  ///
  /// Bₚ is recalculated with every new drawing in Phase 1
  /// This gives users early insights while data is still being collected
  Future<void> _updatePreliminaryBaseline(Cycle cycle) async {
    try {
      // Get all drawings for this cycle
      final drawings = drawingRepo.getForCycle(cycle.startDate, null);
      if (drawings.isEmpty) {
        print('No drawings found for cycle ${cycle.id}');
        return;
      }

      // Take only the first N drawings (up to 19)
      // Reverse because getForCycle returns newest first
      final cycleDrawings = drawings.reversed.take(cycle.drawingCount).toList();

      print('Creating preliminary baseline with ${cycleDrawings.length} drawings');

      // Create preliminary baseline
      final baseline = await baselineCalc.createPreliminaryBaseline(
        cycle.id,
        cycleDrawings,
      );

      // Save baseline
      await baselineRepo.save(baseline);

      // Update cycle reference
      await cycleRepo.updateBaselineReferences(
        cycleId: cycle.id,
        prelimBaselineId: baseline.id,
      );

      print('Preliminary baseline created: ${baseline.id}');
    } catch (e) {
      print('Error updating preliminary baseline: $e');
    }
  }

  /// Create initial baseline at 20 drawings (Phase 1→2 transition)
  ///
  /// This is a critical transition:
  /// 1. Creates B₀ (locked initial baseline) from first 20 drawings
  /// 2. Creates first Bₙ (same as B₀, no smoothing yet)
  /// 3. Deletes Bₚ (no longer needed)
  /// 4. Transitions cycle status to 'active'
  Future<void> _createInitialBaseline(Cycle cycle) async {
    try {
      // Get first 20 drawings for this cycle
      final drawings = drawingRepo.getForCycle(cycle.startDate, null);
      final first20 = drawings.reversed.take(20).toList();

      if (first20.length != 20) {
        throw Exception('Expected 20 drawings for initial baseline, got ${first20.length}');
      }

      print('Creating initial baseline (B₀) with 20 drawings');

      // Create B₀ (initial baseline) - locked for entire cycle
      final b0 = await baselineCalc.createInitialBaseline(cycle.id, first20);
      await baselineRepo.save(b0);
      print('B₀ created: ${b0.id}');

      // Create first Bₙ (rolling baseline) - same as B₀, no smoothing
      // No previous rolling baseline exists, so smoothing level doesn't matter
      final bn = await baselineCalc.createRollingBaseline(
        cycle.id,
        first20,
        null, // No previous rolling baseline
        SmoothingLevel.none,
      );
      await baselineRepo.save(bn);
      print('First Bₙ created: ${bn.id}');

      // Update cycle with baseline references
      await cycleRepo.updateBaselineReferences(
        cycleId: cycle.id,
        initialBaselineId: b0.id,
        rollingBaselineId: bn.id,
      );

      // Delete preliminary baseline (no longer needed)
      if (cycle.prelimBaselineId != null) {
        await baselineRepo.delete(cycle.prelimBaselineId!);
        print('Preliminary baseline deleted: ${cycle.prelimBaselineId}');
      }

      // Cycle status transition to 'active' is handled by incrementDrawingCount()
      print('Phase 1→2 transition complete');
    } catch (e) {
      print('Error creating initial baseline: $e');
    }
  }

  /// Create/update rolling baseline (Phase 2, every 5 drawings)
  ///
  /// Bₙ recalculates every 5 drawings with smoothing applied
  /// Smoothing blends new data with previous Bₙ to reduce volatility
  /// After creating new Bₙ, pattern shift detection runs
  Future<void> _updateRollingBaseline(Cycle cycle) async {
    try {
      // Get last 20 drawings
      final allDrawings = drawingRepo.getForCycle(cycle.startDate, null);
      final last20 = allDrawings.take(20).toList();

      if (last20.length < 20) {
        print('Warning: Only ${last20.length} drawings available for rolling baseline');
      }

      print('Creating rolling baseline with ${last20.length} drawings');

      // Get previous rolling baseline for smoothing
      final previousBn = cycle.rollingBaselineId != null
          ? baselineRepo.getById(cycle.rollingBaselineId!)
          : null;

      // Get smoothing level from user settings
      final settings = settingsRepo.getSettings();

      // Create new Bₙ with smoothing
      final newBn = await baselineCalc.createRollingBaseline(
        cycle.id,
        last20,
        previousBn,
        settings.smoothingFactor,
      );

      // Save new baseline
      await baselineRepo.save(newBn);
      print('New Bₙ created: ${newBn.id}');

      // Update cycle reference to new rolling baseline
      await cycleRepo.updateBaselineReferences(
        cycleId: cycle.id,
        rollingBaselineId: newBn.id,
      );

      // Detect pattern shifts after baseline update
      await _detectPatternShifts(cycle, newBn);
    } catch (e) {
      print('Error updating rolling baseline: $e');
    }
  }

  /// Detect and save pattern shifts
  ///
  /// Compares B₀ vs Bₙ and Bₙ vs previous Bₙ to detect:
  /// - Long-term drift (B₀ hot numbers now below average)
  /// - Short-term surge (multiple numbers jumped significantly)
  /// - Baseline divergence (B₀ and Bₙ patterns differ)
  /// - Correlation breakdown (top pairs no longer co-occurring)
  /// - New dominance (previously uncommon numbers now top performers)
  Future<void> _detectPatternShifts(Cycle cycle, Baseline newBaseline) async {
    try {
      // Get B₀ for comparison
      final b0 = cycle.initialBaselineId != null
          ? baselineRepo.getById(cycle.initialBaselineId!)
          : null;

      if (b0 == null) {
        print('No B₀ available for pattern shift detection');
        return;
      }

      // Get previous Bₙ for surge detection
      final allBn = baselineRepo.getRollingBaselineHistory(cycle.id);
      final previousBn = allBn.length > 1 ? allBn[1] : null;

      // Get latest drawing for shift reference
      final latestDrawing = drawingRepo.getLatest(1).firstOrNull;
      if (latestDrawing == null) {
        print('No latest drawing available for pattern shift');
        return;
      }

      print('Detecting pattern shifts (B₀ vs Bₙ)');

      // Detect shifts using all 5 algorithms
      final shifts = shiftDetector.detectShifts(
        b0: b0,
        bn: newBaseline,
        previous: previousBn,
        drawingId: latestDrawing.id,
      );

      // Save detected shifts to database
      if (shifts.isEmpty) {
        print('No pattern shifts detected');
      } else {
        print('Detected ${shifts.length} pattern shifts');
        for (final shift in shifts) {
          await shiftRepo.save(shift);
          print('  - ${shift.triggerType.name} (${shift.severity.name} severity)');
        }
      }
    } catch (e) {
      print('Error detecting pattern shifts: $e');
    }
  }
}
