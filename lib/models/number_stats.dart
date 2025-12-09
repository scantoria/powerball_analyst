import 'package:freezed_annotation/freezed_annotation.dart';

part 'number_stats.freezed.dart';
part 'number_stats.g.dart';

/// Type of ball
enum BallType {
  white,
  powerball,
}

/// Classification based on deviation
enum Classification {
  /// > +1.5 deviation
  hot,

  /// +0.5 to +1.5 deviation
  warm,

  /// -0.5 to +0.5 deviation
  stable,

  /// -1.5 to -0.5 deviation
  cool,

  /// < -1.5 deviation
  cold,
}

/// Trend direction
enum Trend {
  rising,
  stable,
  falling,
}

/// Computed statistics for a single number within a baseline
/// Used for display and analysis but not persisted directly
@freezed
class NumberStats with _$NumberStats {
  const factory NumberStats({
    /// The ball number (1-69 or 1-26)
    required int number,

    /// Type of ball
    required BallType ballType,

    /// Times drawn in range
    required int frequency,

    /// Statistical expected frequency
    required double expectedFreq,

    /// Standard deviations from mean
    required double deviation,

    /// Percentile rank (1-100)
    required int percentile,

    /// Hot/warm/stable/cool/cold classification
    required Classification classification,

    /// Most recent appearance
    DateTime? lastDrawnDate,

    /// Drawings since last appearance
    @Default(0) int drawingsSince,

    /// Average gap between appearances
    required double avgGap,

    /// Top 5 co-occurring numbers
    @Default([]) List<int> companions,

    /// Rising/stable/falling trend
    required Trend trend,
  }) = _NumberStats;

  factory NumberStats.fromJson(Map<String, dynamic> json) =>
      _$NumberStatsFromJson(json);
}
