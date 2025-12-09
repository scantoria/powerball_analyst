import '../../models/drawing.dart';

/// Analyzes drawing frequency distributions for white balls and powerballs
class FrequencyAnalyzer {
  /// Calculate white ball frequencies from drawings
  /// Returns a map with keys 1-69 and their occurrence counts
  Map<int, int> calculateWhiteballFrequency(List<Drawing> drawings) {
    final freq = <int, int>{};

    // Initialize all numbers 1-69 to 0
    for (int i = 1; i <= 69; i++) {
      freq[i] = 0;
    }

    // Count occurrences
    for (final drawing in drawings) {
      for (final ball in drawing.whiteBalls) {
        if (ball >= 1 && ball <= 69) {
          freq[ball] = (freq[ball] ?? 0) + 1;
        }
      }
    }

    return freq;
  }

  /// Calculate powerball frequencies from drawings
  /// Returns a map with keys 1-26 and their occurrence counts
  Map<int, int> calculatePowerballFrequency(List<Drawing> drawings) {
    final freq = <int, int>{};

    // Initialize all numbers 1-26 to 0
    for (int i = 1; i <= 26; i++) {
      freq[i] = 0;
    }

    // Count occurrences
    for (final drawing in drawings) {
      final pb = drawing.powerball;
      if (pb >= 1 && pb <= 26) {
        freq[pb] = (freq[pb] ?? 0) + 1;
      }
    }

    return freq;
  }

  /// Get top N% of numbers by frequency
  /// percentile: 80 returns top 20% (100-80=20)
  List<int> getTopNumbers(Map<int, int> frequencies, int percentile) {
    if (frequencies.isEmpty) return [];

    final entries = frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final cutoff = (frequencies.length * (100 - percentile) / 100).ceil();
    return entries.take(cutoff).map((e) => e.key).toList()..sort();
  }

  /// Get bottom N% of numbers by frequency
  /// percentile: 20 returns bottom 20%
  List<int> getBottomNumbers(Map<int, int> frequencies, int percentile) {
    if (frequencies.isEmpty) return [];

    final entries = frequencies.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final cutoff = (frequencies.length * percentile / 100).ceil();
    return entries.take(cutoff).map((e) => e.key).toList()..sort();
  }

  /// Find numbers that never appeared (frequency = 0)
  List<int> findNeverDrawn(Map<int, int> frequencies, int maxNumber) {
    final neverDrawn = <int>[];

    for (int i = 1; i <= maxNumber; i++) {
      if (frequencies[i] == 0) {
        neverDrawn.add(i);
      }
    }

    return neverDrawn;
  }
}
