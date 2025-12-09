import 'package:freezed_annotation/freezed_annotation.dart';

part 'pattern_shift.freezed.dart';
part 'pattern_shift.g.dart';

/// Type of pattern shift trigger
enum ShiftTrigger {
  /// 5+ B₀ hot numbers now below average
  longTermDrift,

  /// 3+ numbers jump > +2.0 dev in 5 drawings
  shortTermSurge,

  /// B₀ and Bₙ hot sets differ > 50%
  baselineDivergence,

  /// Top 5 B₀ pairs no longer co-occurring
  correlationBreakdown,

  /// Non-B₀-top-30% number is now #1 or #2
  newDominance,
}

/// Severity level of a pattern shift
enum ShiftSeverity {
  low,
  medium,
  high,
}

/// Records detected pattern shifts that may indicate a cycle change
@freezed
class PatternShift with _$PatternShift {
  const factory PatternShift({
    /// Unique identifier (UUID)
    required String id,

    /// Parent cycle reference
    required String cycleId,

    /// Type of shift detected
    required ShiftTrigger triggerType,

    /// Detection timestamp
    required DateTime detectedAt,

    /// Drawing that triggered shift
    required String drawingId,

    /// Severity level
    required ShiftSeverity severity,

    /// Trigger-specific data (flexible map for different trigger types)
    required Map<String, dynamic> details,

    /// User dismissed alert
    @Default(false) bool isDismissed,

    /// Dismissal timestamp
    DateTime? dismissedAt,

    /// Led to new cycle creation
    @Default(false) bool triggeredNewCycle,
  }) = _PatternShift;

  factory PatternShift.fromJson(Map<String, dynamic> json) =>
      _$PatternShiftFromJson(json);
}
