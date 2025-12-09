import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../models/drawing.dart';
import '../../models/baseline.dart';
import '../../models/settings.dart';
import 'frequency_analyzer.dart';
import 'cooccurrence_analyzer.dart';

/// Main orchestrator for creating all baseline types (B₀, Bₙ, Bₚ)
class BaselineCalculator {
  final FrequencyAnalyzer frequencyAnalyzer;
  final CooccurrenceAnalyzer cooccurrenceAnalyzer;

  BaselineCalculator({
    FrequencyAnalyzer? frequencyAnalyzer,
    CooccurrenceAnalyzer? cooccurrenceAnalyzer,
  })  : frequencyAnalyzer = frequencyAnalyzer ?? FrequencyAnalyzer(),
        cooccurrenceAnalyzer =
            cooccurrenceAnalyzer ?? CooccurrenceAnalyzer();

  /// Create initial baseline (B₀) from first 20 drawings
  /// This baseline is locked for the entire cycle duration
  Future<Baseline> createInitialBaseline(
    String cycleId,
    List<Drawing> drawings,
  ) async {
    if (drawings.length != 20) {
      throw ArgumentError(
          'Initial baseline requires exactly 20 drawings, got ${drawings.length}');
    }

    return _createBaseline(
      cycleId: cycleId,
      drawings: drawings,
      type: BaselineType.initial,
      smoothingFactor: null,
    );
  }

  /// Create rolling baseline (Bₙ) from last 20 drawings with smoothing
  /// Applies smoothing if previousRolling is provided and smoothing != none
  Future<Baseline> createRollingBaseline(
    String cycleId,
    List<Drawing> drawings,
    Baseline? previousRolling,
    SmoothingLevel smoothingLevel,
  ) async {
    if (drawings.length < 20) {
      throw ArgumentError(
          'Rolling baseline requires at least 20 drawings, got ${drawings.length}');
    }

    // Take last 20 drawings
    final last20 = drawings.take(20).toList();

    // Calculate new frequencies
    final newWhiteballFreq =
        frequencyAnalyzer.calculateWhiteballFrequency(last20);
    final newPowerballFreq =
        frequencyAnalyzer.calculatePowerballFrequency(last20);

    // Apply smoothing if previous baseline exists and smoothing enabled
    Map<int, int> whiteballFreq;
    Map<int, int> powerballFreq;
    double? appliedSmoothingFactor;

    if (previousRolling != null && smoothingLevel != SmoothingLevel.none) {
      appliedSmoothingFactor = _getSmoothingFactor(smoothingLevel);
      whiteballFreq = _applySmoothingToFrequencies(
        newWhiteballFreq,
        previousRolling.whiteballFreq,
        appliedSmoothingFactor,
      );
      powerballFreq = _applySmoothingToFrequencies(
        newPowerballFreq,
        previousRolling.powerballFreq,
        appliedSmoothingFactor,
      );
    } else {
      whiteballFreq = newWhiteballFreq;
      powerballFreq = newPowerballFreq;
      appliedSmoothingFactor = null;
    }

    // Calculate cooccurrence (no smoothing for pairs)
    final cooccurrence = cooccurrenceAnalyzer.calculateCooccurrence(last20);

    // Identify hot/cold numbers
    final hotWhiteballs =
        frequencyAnalyzer.getTopNumbers(whiteballFreq, 80); // Top 20%
    final coldWhiteballs =
        frequencyAnalyzer.getBottomNumbers(whiteballFreq, 20); // Bottom 20%
    final neverDrawnWB = frequencyAnalyzer.findNeverDrawn(whiteballFreq, 69);

    final hotPowerballs = frequencyAnalyzer.getTopNumbers(powerballFreq, 80);
    final neverDrawnPB = frequencyAnalyzer.findNeverDrawn(powerballFreq, 26);

    // Calculate statistics
    final statistics = calculateStatistics(whiteballFreq);

    // Create baseline
    return Baseline(
      id: const Uuid().v4(),
      cycleId: cycleId,
      type: BaselineType.rolling,
      drawingRange: DateRange(
        startDate: last20.last.drawDate,
        endDate: last20.first.drawDate,
      ),
      drawingCount: 20,
      whiteballFreq: whiteballFreq,
      powerballFreq: powerballFreq,
      cooccurrence: cooccurrence,
      hotWhiteballs: hotWhiteballs,
      coldWhiteballs: coldWhiteballs,
      neverDrawnWB: neverDrawnWB,
      hotPowerballs: hotPowerballs,
      neverDrawnPB: neverDrawnPB,
      statistics: statistics,
      smoothingFactor: appliedSmoothingFactor,
      createdAt: DateTime.now(),
    );
  }

  /// Create preliminary baseline (Bₚ) during Phase 1
  /// Used before B₀ is locked (1-19 drawings)
  Future<Baseline> createPreliminaryBaseline(
    String cycleId,
    List<Drawing> drawings,
  ) async {
    if (drawings.isEmpty) {
      throw ArgumentError('Preliminary baseline requires at least 1 drawing');
    }

    if (drawings.length >= 20) {
      throw ArgumentError(
          'Preliminary baseline is only for <20 drawings, got ${drawings.length}');
    }

    return _createBaseline(
      cycleId: cycleId,
      drawings: drawings,
      type: BaselineType.preliminary,
      smoothingFactor: null,
    );
  }

  /// Internal method to create a baseline from drawings
  Future<Baseline> _createBaseline({
    required String cycleId,
    required List<Drawing> drawings,
    required BaselineType type,
    double? smoothingFactor,
  }) async {
    // Calculate frequencies
    final whiteballFreq =
        frequencyAnalyzer.calculateWhiteballFrequency(drawings);
    final powerballFreq =
        frequencyAnalyzer.calculatePowerballFrequency(drawings);

    // Calculate cooccurrence
    final cooccurrence = cooccurrenceAnalyzer.calculateCooccurrence(drawings);

    // Identify hot/cold numbers
    final hotWhiteballs =
        frequencyAnalyzer.getTopNumbers(whiteballFreq, 80); // Top 20%
    final coldWhiteballs =
        frequencyAnalyzer.getBottomNumbers(whiteballFreq, 20); // Bottom 20%
    final neverDrawnWB = frequencyAnalyzer.findNeverDrawn(whiteballFreq, 69);

    final hotPowerballs = frequencyAnalyzer.getTopNumbers(powerballFreq, 80);
    final neverDrawnPB = frequencyAnalyzer.findNeverDrawn(powerballFreq, 26);

    // Calculate statistics
    final statistics = calculateStatistics(whiteballFreq);

    // Create baseline model
    return Baseline(
      id: const Uuid().v4(),
      cycleId: cycleId,
      type: type,
      drawingRange: DateRange(
        startDate: drawings.last.drawDate,
        endDate: drawings.first.drawDate,
      ),
      drawingCount: drawings.length,
      whiteballFreq: whiteballFreq,
      powerballFreq: powerballFreq,
      cooccurrence: cooccurrence,
      hotWhiteballs: hotWhiteballs,
      coldWhiteballs: coldWhiteballs,
      neverDrawnWB: neverDrawnWB,
      hotPowerballs: hotPowerballs,
      neverDrawnPB: neverDrawnPB,
      statistics: statistics,
      smoothingFactor: smoothingFactor,
      createdAt: DateTime.now(),
    );
  }

  /// Calculate statistics for frequency distribution
  Statistics calculateStatistics(Map<int, int> frequencies) {
    final values = frequencies.values.toList()..sort();

    if (values.isEmpty) {
      return const Statistics(
        mean: 0.0,
        stdDev: 0.0,
        median: 0.0,
        min: 0,
        max: 0,
      );
    }

    // Mean
    final sum = values.reduce((a, b) => a + b);
    final mean = sum / values.length;

    // Standard deviation
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    final stdDev = sqrt(variance);

    // Median
    final median = values.length.isOdd
        ? values[values.length ~/ 2].toDouble()
        : (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2.0;

    return Statistics(
      mean: mean,
      stdDev: stdDev,
      median: median,
      min: values.first,
      max: values.last,
    );
  }

  /// Apply smoothing to rolling baseline frequencies
  /// Formula: smoothedValue = (prevValue × smoothingFactor) + (newValue × (1 - smoothingFactor))
  Map<int, int> _applySmoothingToFrequencies(
    Map<int, int> newFreq,
    Map<int, int> prevFreq,
    double smoothingFactor,
  ) {
    final smoothed = <int, int>{};

    for (final entry in newFreq.entries) {
      final number = entry.key;
      final newValue = entry.value;
      final prevValue = prevFreq[number] ?? 0;

      final smoothedValue =
          (prevValue * smoothingFactor + newValue * (1 - smoothingFactor))
              .round();
      smoothed[number] = smoothedValue;
    }

    return smoothed;
  }

  /// Get smoothing factor from smoothing level
  double _getSmoothingFactor(SmoothingLevel level) {
    switch (level) {
      case SmoothingLevel.none:
        return 0.0; // 0% previous, 100% new
      case SmoothingLevel.light:
        return 0.85; // 85% previous, 15% new
      case SmoothingLevel.normal:
        return 0.70; // 70% previous, 30% new
      case SmoothingLevel.heavy:
        return 0.50; // 50% previous, 50% new
    }
  }

  /// Determine if rolling baseline should be recalculated
  /// Returns true every 5 drawings after the initial 20
  /// (e.g., drawings 25, 30, 35, 40, ...)
  bool shouldRecalculateRolling(int currentDrawingCount) {
    // Don't recalculate during Phase 1 (< 20 drawings)
    if (currentDrawingCount <= 20) return false;

    // Recalculate every 5 drawings after the initial 20
    return (currentDrawingCount - 20) % 5 == 0;
  }
}
