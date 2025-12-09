import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/number_stats.dart';
import '../models/pattern_shift.dart';
import '../services/analysis/frequency_analyzer.dart';
import '../services/analysis/cooccurrence_analyzer.dart';
import '../services/analysis/baseline_calculator.dart';
import '../services/analysis/deviation_calculator.dart';
import '../services/analysis/pattern_shift_detector.dart';
import '../services/recommendation/pick_generator.dart';
import '../services/recommendation/validation_service.dart';
import 'baseline_providers.dart';
import 'cycle_providers.dart';
import 'repository_providers.dart';

// ========== Service Providers ==========

/// Provider for FrequencyAnalyzer service
final frequencyAnalyzerProvider = Provider<FrequencyAnalyzer>((ref) {
  return FrequencyAnalyzer();
});

/// Provider for CooccurrenceAnalyzer service
final cooccurrenceAnalyzerProvider = Provider<CooccurrenceAnalyzer>((ref) {
  return CooccurrenceAnalyzer();
});

/// Provider for BaselineCalculator service
final baselineCalculatorProvider = Provider<BaselineCalculator>((ref) {
  return BaselineCalculator(
    frequencyAnalyzer: ref.watch(frequencyAnalyzerProvider),
    cooccurrenceAnalyzer: ref.watch(cooccurrenceAnalyzerProvider),
  );
});

/// Provider for DeviationCalculator service
final deviationCalculatorProvider = Provider<DeviationCalculator>((ref) {
  return DeviationCalculator();
});

/// Provider for PatternShiftDetector service
final patternShiftDetectorProvider = Provider<PatternShiftDetector>((ref) {
  return PatternShiftDetector();
});

/// Provider for PickGenerator service
final pickGeneratorProvider = Provider<PickGenerator>((ref) {
  return PickGenerator();
});

/// Provider for ValidationService
final validationServiceProvider = Provider<ValidationService>((ref) {
  return ValidationService();
});

// ========== Analysis Data Providers ==========

/// Provider for number statistics from active baseline
final numberStatsProvider = Provider<List<NumberStats>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  if (baseline == null) return [];

  final deviationCalc = ref.watch(deviationCalculatorProvider);
  return deviationCalc.calculateNumberStats(baseline);
});

/// Provider for hot white balls from active baseline
final hotWhiteballsProvider = Provider<List<int>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  return baseline?.hotWhiteballs ?? [];
});

/// Provider for cold white balls from active baseline
final coldWhiteballsProvider = Provider<List<int>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  return baseline?.coldWhiteballs ?? [];
});

/// Provider for never drawn white balls
final neverDrawnWhiteballsProvider = Provider<List<int>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  return baseline?.neverDrawnWB ?? [];
});

/// Provider for hot powerballs from active baseline
final hotPowerballsProvider = Provider<List<int>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  return baseline?.hotPowerballs ?? [];
});

/// Provider for never drawn powerballs
final neverDrawnPowerballsProvider = Provider<List<int>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  return baseline?.neverDrawnPB ?? [];
});

/// Provider for cooccurrence pairs (top companions)
final topPairsProvider = Provider<List<MapEntry<String, int>>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  if (baseline == null) return [];

  final pairs = baseline.cooccurrence.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return pairs.take(20).toList();
});

/// Provider for pattern shifts in current cycle
final patternShiftsProvider = Provider<List<PatternShift>>((ref) {
  final currentCycle = ref.watch(currentCycleProvider);
  if (currentCycle == null) return [];

  final shiftRepo = ref.watch(patternShiftRepositoryProvider);
  return shiftRepo.getByCycleId(currentCycle.id);
});

/// Provider for active (non-dismissed) pattern shifts
final activeShiftsProvider = Provider<List<PatternShift>>((ref) {
  final shifts = ref.watch(patternShiftsProvider);
  return shifts.where((shift) => !shift.isDismissed).toList();
});

/// Provider for shift alerts count
final shiftAlertsCountProvider = Provider<int>((ref) {
  final activeShifts = ref.watch(activeShiftsProvider);
  return activeShifts.length;
});

/// Provider for most recent pattern shift
final latestShiftProvider = Provider<PatternShift?>((ref) {
  final shifts = ref.watch(patternShiftsProvider);
  if (shifts.isEmpty) return null;

  return shifts.reduce(
    (latest, shift) => shift.detectedAt.isAfter(latest.detectedAt)
        ? shift
        : latest,
  );
});

// ========== Heat Map Data ==========

/// Provider for heat map data (number -> frequency)
final heatMapDataProvider = Provider<Map<int, int>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  return baseline?.whiteballFreq ?? {};
});

/// Provider for powerball heat map data
final powerballHeatMapProvider = Provider<Map<int, int>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  return baseline?.powerballFreq ?? {};
});

// ========== Analysis Statistics ==========

/// Provider for analysis statistics summary
final analysisStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final baseline = ref.watch(activeBaselineProvider);
  if (baseline == null) {
    return {
      'drawingCount': 0,
      'mean': 0.0,
      'stdDev': 0.0,
      'hotCount': 0,
      'coldCount': 0,
      'neverDrawnCount': 0,
    };
  }

  return {
    'drawingCount': baseline.drawingCount,
    'mean': baseline.statistics.mean,
    'stdDev': baseline.statistics.stdDev,
    'median': baseline.statistics.median,
    'min': baseline.statistics.min,
    'max': baseline.statistics.max,
    'hotCount': baseline.hotWhiteballs.length,
    'coldCount': baseline.coldWhiteballs.length,
    'neverDrawnCount': baseline.neverDrawnWB.length,
  };
});

/// Provider for baseline readiness status
final baselineReadyProvider = Provider<bool>((ref) {
  final currentCycle = ref.watch(currentCycleProvider);
  if (currentCycle == null) return false;

  final isPhase1 = ref.watch(isPhase1Provider);
  if (isPhase1) {
    // In Phase 1, check if we have preliminary baseline
    return currentCycle.prelimBaselineId != null;
  }

  // In Phase 2, check if we have both B₀ and Bₙ
  return currentCycle.initialBaselineId != null &&
      currentCycle.rollingBaselineId != null;
});
