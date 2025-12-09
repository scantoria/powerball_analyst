import 'package:freezed_annotation/freezed_annotation.dart';

part 'baseline.freezed.dart';
part 'baseline.g.dart';

/// Type of baseline
enum BaselineType {
  /// B₀: Initial baseline (first 20 drawings), locked
  initial,

  /// Bₙ: Rolling baseline (last 20 drawings), recalculated every 5
  rolling,

  /// Bₚ: Preliminary baseline (Phase 1, before B₀ lock)
  preliminary,
}

/// Date range for a baseline
@freezed
class DateRange with _$DateRange {
  const factory DateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) = _DateRange;

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFromJson(json);
}

/// Statistical metrics for a baseline
@freezed
class Statistics with _$Statistics {
  const factory Statistics({
    /// Average frequency
    required double mean,

    /// Standard deviation
    required double stdDev,

    /// Median frequency
    required double median,

    /// Minimum frequency
    required int min,

    /// Maximum frequency
    required int max,
  }) = _Statistics;

  factory Statistics.fromJson(Map<String, dynamic> json) =>
      _$StatisticsFromJson(json);
}

/// Represents a computed statistical snapshot of drawing data
@freezed
class Baseline with _$Baseline {
  const factory Baseline({
    /// Unique identifier (UUID)
    required String id,

    /// Parent cycle reference
    required String cycleId,

    /// Type of baseline (initial, rolling, preliminary)
    required BaselineType type,

    /// Start and end dates of drawings
    required DateRange drawingRange,

    /// Number of drawings analyzed
    required int drawingCount,

    /// Frequency map for white balls 1-69
    required Map<int, int> whiteballFreq,

    /// Frequency map for powerballs 1-26
    required Map<int, int> powerballFreq,

    /// Pair frequency map (key format: '12-34')
    required Map<String, int> cooccurrence,

    /// Top 20% white balls
    required List<int> hotWhiteballs,

    /// Bottom 20% white balls
    required List<int> coldWhiteballs,

    /// White balls with 0 frequency
    required List<int> neverDrawnWB,

    /// Top 20% Powerballs
    required List<int> hotPowerballs,

    /// Powerballs with 0 frequency
    required List<int> neverDrawnPB,

    /// Statistical metrics
    required Statistics statistics,

    /// Applied smoothing factor (for Bₙ only)
    double? smoothingFactor,

    /// Calculation timestamp
    required DateTime createdAt,
  }) = _Baseline;

  factory Baseline.fromJson(Map<String, dynamic> json) =>
      _$BaselineFromJson(json);
}
