import 'package:uuid/uuid.dart';
import '../../models/baseline.dart';
import '../../models/pattern_shift.dart';
import 'deviation_calculator.dart';

/// Detects significant pattern changes that may indicate a cycle transition
class PatternShiftDetector {
  final DeviationCalculator deviationCalculator;

  PatternShiftDetector({DeviationCalculator? deviationCalculator})
      : deviationCalculator = deviationCalculator ?? DeviationCalculator();

  /// Detect all pattern shifts between baselines
  /// Returns list of detected shifts (can be empty if no shifts detected)
  List<PatternShift> detectShifts({
    required Baseline b0,
    required Baseline bn,
    Baseline? previous,
    required String drawingId,
  }) {
    final shifts = <PatternShift>[];

    // 1. Long-term drift
    final drift = _detectLongTermDrift(b0, bn);
    if (drift != null) {
      shifts.add(drift.copyWith(drawingId: drawingId));
    }

    // 2. Short-term surge (requires previous baseline)
    if (previous != null) {
      final surge = _detectShortTermSurge(bn, previous);
      if (surge != null) {
        shifts.add(surge.copyWith(drawingId: drawingId));
      }
    }

    // 3. Baseline divergence
    final divergence = _detectBaselineDivergence(b0, bn);
    if (divergence != null) {
      shifts.add(divergence.copyWith(drawingId: drawingId));
    }

    // 4. Correlation breakdown
    final correlation = _detectCorrelationBreakdown(b0, bn);
    if (correlation != null) {
      shifts.add(correlation.copyWith(drawingId: drawingId));
    }

    // 5. New dominance
    final dominance = _detectNewDominance(b0, bn);
    if (dominance != null) {
      shifts.add(dominance.copyWith(drawingId: drawingId));
    }

    return shifts;
  }

  /// Detect Long-Term Drift: 5+ B₀ hot numbers now below Bₙ average
  PatternShift? _detectLongTermDrift(Baseline b0, Baseline bn) {
    final driftedNumbers = <int>[];

    for (final hotNumber in b0.hotWhiteballs) {
      final currentFreq = bn.whiteballFreq[hotNumber] ?? 0;
      if (currentFreq < bn.statistics.mean) {
        driftedNumbers.add(hotNumber);
      }
    }

    if (driftedNumbers.length >= 5) {
      return PatternShift(
        id: const Uuid().v4(),
        cycleId: bn.cycleId,
        triggerType: ShiftTrigger.longTermDrift,
        detectedAt: DateTime.now(),
        drawingId: '', // Set by caller
        severity: _calculateDriftSeverity(driftedNumbers.length),
        details: {
          'driftedCount': driftedNumbers.length,
          'driftedNumbers': driftedNumbers,
          'meanFrequency': bn.statistics.mean,
        },
      );
    }

    return null;
  }

  /// Calculate severity for long-term drift
  ShiftSeverity _calculateDriftSeverity(int count) {
    if (count >= 8) return ShiftSeverity.high;
    if (count >= 6) return ShiftSeverity.medium;
    return ShiftSeverity.low;
  }

  /// Detect Short-Term Surge: 3+ numbers jump > +2.0 deviation in last 5 drawings
  PatternShift? _detectShortTermSurge(Baseline recent, Baseline previous) {
    final surgedNumbers = <int, double>{};

    for (final entry in recent.whiteballFreq.entries) {
      final number = entry.key;
      final recentFreq = entry.value;
      final prevFreq = previous.whiteballFreq[number] ?? 0;

      // Calculate deviations
      final recentDev = deviationCalculator.calculateDeviation(
        recentFreq,
        recent.statistics.mean,
        recent.statistics.stdDev,
      );
      final prevDev = deviationCalculator.calculateDeviation(
        prevFreq,
        previous.statistics.mean,
        previous.statistics.stdDev,
      );

      final jump = recentDev - prevDev;
      if (jump > 2.0) {
        surgedNumbers[number] = jump;
      }
    }

    if (surgedNumbers.length >= 3) {
      return PatternShift(
        id: const Uuid().v4(),
        cycleId: recent.cycleId,
        triggerType: ShiftTrigger.shortTermSurge,
        detectedAt: DateTime.now(),
        drawingId: '',
        severity:
            surgedNumbers.length >= 5 ? ShiftSeverity.high : ShiftSeverity.medium,
        details: {
          'surgedCount': surgedNumbers.length,
          'surgedNumbers': surgedNumbers.keys.toList(),
          'deviationJumps': surgedNumbers,
        },
      );
    }

    return null;
  }

  /// Detect Baseline Divergence: B₀ and Bₙ hot sets differ > 50%
  PatternShift? _detectBaselineDivergence(Baseline b0, Baseline bn) {
    final b0Set = Set<int>.from(b0.hotWhiteballs);
    final bnSet = Set<int>.from(bn.hotWhiteballs);

    final intersection = b0Set.intersection(bnSet).length;
    final union = b0Set.union(bnSet).length;

    if (union == 0) return null;

    final overlap = (intersection / union) * 100;

    if (overlap < 50.0) {
      return PatternShift(
        id: const Uuid().v4(),
        cycleId: bn.cycleId,
        triggerType: ShiftTrigger.baselineDivergence,
        detectedAt: DateTime.now(),
        drawingId: '',
        severity: overlap < 30 ? ShiftSeverity.high : ShiftSeverity.medium,
        details: {
          'overlapPercentage': overlap,
          'b0HotNumbers': b0.hotWhiteballs,
          'bnHotNumbers': bn.hotWhiteballs,
          'commonHot': b0Set.intersection(bnSet).toList(),
        },
      );
    }

    return null;
  }

  /// Detect Correlation Breakdown: Top 5 B₀ pairs no longer co-occurring in Bₙ
  PatternShift? _detectCorrelationBreakdown(Baseline b0, Baseline bn) {
    final b0TopPairs = b0.cooccurrence.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (b0TopPairs.length < 5) return null;

    final top5Pairs = b0TopPairs.take(5).toList();
    final brokenPairs = <String>[];

    for (final pair in top5Pairs) {
      final bnFreq = bn.cooccurrence[pair.key] ?? 0;
      // Consider broken if frequency drops below 25% of original
      if (bnFreq < (pair.value * 0.25)) {
        brokenPairs.add(pair.key);
      }
    }

    if (brokenPairs.length >= 3) {
      return PatternShift(
        id: const Uuid().v4(),
        cycleId: bn.cycleId,
        triggerType: ShiftTrigger.correlationBreakdown,
        detectedAt: DateTime.now(),
        drawingId: '',
        severity:
            brokenPairs.length >= 4 ? ShiftSeverity.high : ShiftSeverity.medium,
        details: {
          'brokenPairsCount': brokenPairs.length,
          'brokenPairs': brokenPairs,
          'b0TopPairs': top5Pairs.map((e) => e.key).toList(),
        },
      );
    }

    return null;
  }

  /// Detect New Dominance: Non-B₀-top-30% number is now #1 or #2 in Bₙ
  PatternShift? _detectNewDominance(Baseline b0, Baseline bn) {
    // Get top 30% from B₀ (approximately 21 numbers out of 69)
    final b0Top30Count = (69 * 0.3).ceil();
    final b0Top30 = b0.whiteballFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final b0Top30Numbers = b0Top30.take(b0Top30Count).map((e) => e.key).toSet();

    // Get top 2 from Bₙ
    final bnTop = bn.whiteballFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (bnTop.length < 2) return null;

    final bnTop2 = bnTop.take(2).toList();

    final newDominant = <int>[];
    for (final entry in bnTop2) {
      if (!b0Top30Numbers.contains(entry.key)) {
        newDominant.add(entry.key);
      }
    }

    if (newDominant.isNotEmpty) {
      return PatternShift(
        id: const Uuid().v4(),
        cycleId: bn.cycleId,
        triggerType: ShiftTrigger.newDominance,
        detectedAt: DateTime.now(),
        drawingId: '',
        severity: newDominant.length == 2 ? ShiftSeverity.high : ShiftSeverity.medium,
        details: {
          'newDominantNumbers': newDominant,
          'bnTop2': bnTop2
              .map((e) => {'number': e.key, 'frequency': e.value})
              .toList(),
          'b0Top30Count': b0Top30Count,
        },
      );
    }

    return null;
  }
}
