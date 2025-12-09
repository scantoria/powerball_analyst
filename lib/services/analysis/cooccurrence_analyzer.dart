import '../../models/drawing.dart';

/// Analyzes co-occurrence patterns between number pairs in drawings
class CooccurrenceAnalyzer {
  /// Calculate co-occurrence frequencies for all white ball pairs
  /// Returns map with keys like "12-34" (always smaller-larger format)
  Map<String, int> calculateCooccurrence(List<Drawing> drawings) {
    final cooccurrence = <String, int>{};

    for (final drawing in drawings) {
      final balls = drawing.whiteBalls;

      // Generate all pairs in this drawing (C(5,2) = 10 pairs)
      for (int i = 0; i < balls.length; i++) {
        for (int j = i + 1; j < balls.length; j++) {
          final key = _generatePairKey(balls[i], balls[j]);
          cooccurrence[key] = (cooccurrence[key] ?? 0) + 1;
        }
      }
    }

    return cooccurrence;
  }

  /// Find top N companions for a specific number
  /// Returns list of numbers that most frequently appear with the given number
  List<int> findTopCompanions(
    int number,
    Map<String, int> cooccurrence,
    int limit,
  ) {
    final companions = <MapEntry<int, int>>[];

    // Find all pairs involving this number
    for (final entry in cooccurrence.entries) {
      final parts = entry.key.split('-');
      final num1 = int.parse(parts[0]);
      final num2 = int.parse(parts[1]);

      if (num1 == number) {
        companions.add(MapEntry(num2, entry.value));
      } else if (num2 == number) {
        companions.add(MapEntry(num1, entry.value));
      }
    }

    // Sort by frequency (descending) and return top N
    companions.sort((a, b) => b.value.compareTo(a.value));
    return companions.take(limit).map((e) => e.key).toList();
  }

  /// Get pair frequency for two specific numbers
  int getPairFrequency(int num1, int num2, Map<String, int> cooccurrence) {
    final key = _generatePairKey(num1, num2);
    return cooccurrence[key] ?? 0;
  }

  /// Generate consistent pair key (always smaller-larger format)
  /// Example: _generatePairKey(34, 12) returns "12-34"
  String _generatePairKey(int num1, int num2) {
    final smaller = num1 < num2 ? num1 : num2;
    final larger = num1 > num2 ? num1 : num2;
    return '$smaller-$larger';
  }
}
