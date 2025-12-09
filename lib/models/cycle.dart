import 'package:freezed_annotation/freezed_annotation.dart';

part 'cycle.freezed.dart';
part 'cycle.g.dart';

/// Status of a pattern cycle
enum CycleStatus {
  /// Phase 1: Building baseline (drawings 1-20)
  collecting,

  /// Phase 2: Active analysis with locked B₀
  active,

  /// Cycle ended, archived for history
  closed,
}

/// Represents a pattern cycle period for analysis
@freezed
class Cycle with _$Cycle {
  const factory Cycle({
    /// Unique identifier (UUID)
    required String id,

    /// Optional user-defined name
    String? name,

    /// Cycle start date
    required DateTime startDate,

    /// Cycle end date (null if active)
    DateTime? endDate,

    /// Current status of the cycle
    required CycleStatus status,

    /// Number of drawings in cycle
    @Default(0) int drawingCount,

    /// Reference to B₀ baseline (initial)
    String? initialBaselineId,

    /// Reference to current Bₙ (rolling)
    String? rollingBaselineId,

    /// Reference to Bₚ (preliminary, Phase 1 only)
    String? prelimBaselineId,

    /// User notes about this cycle
    String? notes,

    /// Timestamp when created
    required DateTime createdAt,

    /// Timestamp when closed
    DateTime? closedAt,
  }) = _Cycle;

  factory Cycle.fromJson(Map<String, dynamic> json) => _$CycleFromJson(json);
}
