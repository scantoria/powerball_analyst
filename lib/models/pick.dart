import 'package:freezed_annotation/freezed_annotation.dart';

part 'pick.freezed.dart';
part 'pick.g.dart';

/// Represents a user's number selection for a specific drawing
@freezed
class Pick with _$Pick {
  const factory Pick({
    /// Unique identifier (UUID)
    required String id,

    /// Parent cycle reference
    required String cycleId,

    /// 5 selected white balls (1-69)
    required List<int> whiteBalls,

    /// Selected Powerball (1-26)
    required int powerball,

    /// Target drawing date
    required DateTime targetDrawDate,

    /// True if auto-generated
    @Default(false) bool isAutoPick,

    /// True if created during Phase 1
    @Default(false) bool isPreliminary,

    /// Matches after drawing (0-6), null before evaluation
    int? matchCount,

    /// Powerball matched?, null before evaluation
    bool? powerballMatch,

    /// Sum of white balls
    required int sumTotal,

    /// Count of odd numbers
    required int oddCount,

    /// Auto-pick reasoning/explanation
    String? explanation,

    /// Selection timestamp
    required DateTime createdAt,

    /// When matched against result
    DateTime? evaluatedAt,
  }) = _Pick;

  factory Pick.fromJson(Map<String, dynamic> json) => _$PickFromJson(json);
}
