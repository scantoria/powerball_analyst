import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../models/baseline.dart';
import '../../models/pick.dart';
import '../analysis/cooccurrence_analyzer.dart';

/// Generates intelligent number picks based on baseline data and analysis
class PickGenerator {
  final CooccurrenceAnalyzer cooccurrenceAnalyzer;
  final double frequencyWeight;
  final double companionWeight;

  PickGenerator({
    CooccurrenceAnalyzer? cooccurrenceAnalyzer,
    this.frequencyWeight = 0.6,
    this.companionWeight = 0.4,
  }) : cooccurrenceAnalyzer =
            cooccurrenceAnalyzer ?? CooccurrenceAnalyzer();

  /// Generate an auto-pick based on baseline data
  Future<Pick> generateAutoPick({
    required String cycleId,
    required Baseline baseline,
    required DateTime targetDrawDate,
    bool isPreliminary = false,
  }) async {
    // Calculate scores for each number
    final scores = _calculateNumberScores(baseline);

    // Select top 5 numbers by weighted random selection
    final whiteBalls = _selectWhiteBalls(scores);

    // Select powerball (weighted by frequency)
    final powerball = _selectPowerball(baseline.powerballFreq);

    // Calculate metadata
    final sumTotal = whiteBalls.reduce((a, b) => a + b);
    final oddCount = whiteBalls.where((n) => n.isOdd).length;

    // Generate explanation
    final explanation = _generateExplanation(whiteBalls, powerball, baseline);

    return Pick(
      id: const Uuid().v4(),
      cycleId: cycleId,
      whiteBalls: whiteBalls..sort(),
      powerball: powerball,
      targetDrawDate: targetDrawDate,
      isAutoPick: true,
      isPreliminary: isPreliminary,
      sumTotal: sumTotal,
      oddCount: oddCount,
      explanation: explanation,
      createdAt: DateTime.now(),
    );
  }

  /// Calculate weighted scores for each number
  /// Score = (frequency score × 0.6) + (companion score × 0.4)
  Map<int, double> _calculateNumberScores(Baseline baseline) {
    final scores = <int, double>{};
    final maxFreq = baseline.statistics.max.toDouble();

    if (maxFreq == 0) {
      // Fallback to uniform distribution if no frequency data
      for (int i = 1; i <= 69; i++) {
        scores[i] = 1.0;
      }
      return scores;
    }

    for (final entry in baseline.whiteballFreq.entries) {
      final number = entry.key;
      final frequency = entry.value;

      // Frequency score (normalized 0-1)
      final freqScore = frequency / maxFreq;

      // Companion score (average frequency of top companions)
      final companions = cooccurrenceAnalyzer.findTopCompanions(
        number,
        baseline.cooccurrence,
        5,
      );

      double companionScore = 0.0;
      if (companions.isNotEmpty) {
        final companionFreqs =
            companions.map((c) => baseline.whiteballFreq[c] ?? 0);
        final avgCompanionFreq =
            companionFreqs.reduce((a, b) => a + b) / companions.length;
        companionScore = avgCompanionFreq / maxFreq;
      }

      // Weighted total score
      scores[number] =
          (freqScore * frequencyWeight) + (companionScore * companionWeight);
    }

    return scores;
  }

  /// Select 5 white balls using weighted random selection
  List<int> _selectWhiteBalls(Map<int, double> scores) {
    final selected = <int>[];
    final random = Random();
    final scoresCopy = Map<int, double>.from(scores);

    while (selected.length < 5 && scoresCopy.isNotEmpty) {
      // Calculate total score
      final totalScore = scoresCopy.values.reduce((a, b) => a + b);

      if (totalScore == 0) {
        // Fallback: select remaining numbers randomly
        final remaining = scoresCopy.keys.toList()..shuffle(random);
        selected.addAll(remaining.take(5 - selected.length));
        break;
      }

      // Weighted random selection
      double rand = random.nextDouble() * totalScore;

      for (final entry in scoresCopy.entries) {
        rand -= entry.value;
        if (rand <= 0) {
          selected.add(entry.key);
          scoresCopy.remove(entry.key);
          break;
        }
      }
    }

    return selected..sort();
  }

  /// Select powerball weighted by frequency
  int _selectPowerball(Map<int, int> powerballFreq) {
    final random = Random();
    final totalFreq = powerballFreq.values.reduce((a, b) => a + b);

    if (totalFreq == 0) {
      // Fallback: random selection
      return random.nextInt(26) + 1;
    }

    double rand = random.nextDouble() * totalFreq;

    for (final entry in powerballFreq.entries) {
      rand -= entry.value;
      if (rand <= 0) {
        return entry.key;
      }
    }

    // Fallback (should rarely happen)
    return powerballFreq.keys.isNotEmpty
        ? powerballFreq.keys.first
        : random.nextInt(26) + 1;
  }

  /// Generate explanation text for the pick
  String _generateExplanation(
    List<int> whiteBalls,
    int powerball,
    Baseline baseline,
  ) {
    final hotCount =
        whiteBalls.where((n) => baseline.hotWhiteballs.contains(n)).length;
    final totalFreq =
        whiteBalls.map((n) => baseline.whiteballFreq[n] ?? 0).reduce((a, b) => a + b);
    final avgFreq = totalFreq / 5;

    final baselineType = _getBaselineTypeLabel(baseline.type);

    return 'Auto-pick based on $baselineType baseline: '
        '$hotCount hot numbers, average frequency: ${avgFreq.toStringAsFixed(1)}. '
        'Powerball $powerball selected from top performers.';
  }

  /// Get human-readable baseline type label
  String _getBaselineTypeLabel(BaselineType type) {
    switch (type) {
      case BaselineType.initial:
        return 'B₀';
      case BaselineType.rolling:
        return 'Bₙ';
      case BaselineType.preliminary:
        return 'Bₚ';
    }
  }
}
