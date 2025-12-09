import '../../models/baseline.dart';
import '../../models/number_stats.dart';
import 'cooccurrence_analyzer.dart';

/// Calculates statistical deviations and classifies numbers
class DeviationCalculator {
  final CooccurrenceAnalyzer cooccurrenceAnalyzer;

  DeviationCalculator({CooccurrenceAnalyzer? cooccurrenceAnalyzer})
      : cooccurrenceAnalyzer =
            cooccurrenceAnalyzer ?? CooccurrenceAnalyzer();

  /// Calculate NumberStats for all white balls in a baseline
  List<NumberStats> calculateNumberStats(Baseline baseline) {
    final stats = <NumberStats>[];
    final mean = baseline.statistics.mean;
    final stdDev = baseline.statistics.stdDev;

    for (final entry in baseline.whiteballFreq.entries) {
      final number = entry.key;
      final frequency = entry.value;

      // Calculate deviation
      final deviation = calculateDeviation(frequency, mean, stdDev);

      // Classify
      final classification = classifyByDeviation(deviation);

      // Calculate percentile
      final percentile = calculatePercentile(frequency, baseline.whiteballFreq);

      // Expected frequency (uniform distribution: 20 drawings × 5 balls / 69 numbers)
      final expectedFreq = baseline.drawingCount * 5 / 69.0;

      // Find companions
      final companions = cooccurrenceAnalyzer.findTopCompanions(
        number,
        baseline.cooccurrence,
        5,
      );

      stats.add(NumberStats(
        number: number,
        ballType: BallType.white,
        frequency: frequency,
        expectedFreq: expectedFreq,
        deviation: deviation,
        percentile: percentile,
        classification: classification,
        companions: companions,
        trend: Trend.stable, // Default, calculated when comparing baselines
        avgGap: 0.0, // Requires full drawing history
        drawingsSince: 0, // Requires full drawing history
      ));
    }

    return stats..sort((a, b) => b.frequency.compareTo(a.frequency));
  }

  /// Calculate deviation for a specific number
  /// Formula: (frequency - mean) / stdDev
  double calculateDeviation(int frequency, double mean, double stdDev) {
    if (stdDev == 0) return 0.0;
    return (frequency - mean) / stdDev;
  }

  /// Classify number based on deviation thresholds
  Classification classifyByDeviation(double deviation) {
    if (deviation > 1.5) return Classification.hot;
    if (deviation >= 0.5) return Classification.warm;
    if (deviation >= -0.5) return Classification.stable;
    if (deviation >= -1.5) return Classification.cool;
    return Classification.cold;
  }

  /// Calculate percentile rank for a number
  /// Returns 1-100 percentile
  int calculatePercentile(int frequency, Map<int, int> allFrequencies) {
    final sorted = allFrequencies.values.toList()..sort();

    if (sorted.isEmpty) return 50;

    // Find the index of this frequency
    int lessThan = 0;
    for (final freq in sorted) {
      if (freq < frequency) lessThan++;
    }

    // Calculate percentile
    return ((lessThan / sorted.length) * 100).round().clamp(1, 100);
  }

  /// Determine trend by comparing with previous baseline
  /// Returns rising/stable/falling based on frequency change
  Trend calculateTrend(int number, Baseline current, Baseline? previous) {
    if (previous == null) return Trend.stable;

    final currentFreq = current.whiteballFreq[number] ?? 0;
    final previousFreq = previous.whiteballFreq[number] ?? 0;

    final difference = currentFreq - previousFreq;

    if (difference > 2) return Trend.rising;
    if (difference < -2) return Trend.falling;
    return Trend.stable;
  }

  /// Calculate NumberStats with trend information
  /// Requires previous baseline for trend calculation
  List<NumberStats> calculateNumberStatsWithTrend(
    Baseline current,
    Baseline? previous,
  ) {
    final stats = calculateNumberStats(current);

    if (previous == null) return stats;

    // Update trend for each number
    return stats.map((stat) {
      final trend = calculateTrend(stat.number, current, previous);
      return stat.copyWith(trend: trend);
    }).toList();
  }
}
