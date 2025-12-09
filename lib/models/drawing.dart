import 'package:freezed_annotation/freezed_annotation.dart';

part 'drawing.freezed.dart';
part 'drawing.g.dart';

/// Represents a single Powerball lottery drawing result
@freezed
class Drawing with _$Drawing {
  const factory Drawing({
    /// Unique identifier (format: 'drawing_YYYYMMDD')
    required String id,

    /// Date of the drawing
    required DateTime drawDate,

    /// 5 white ball numbers (1-69), sorted ascending
    required List<int> whiteBalls,

    /// Powerball number (1-26)
    required int powerball,

    /// Power Play multiplier (2-10), nullable
    int? multiplier,

    /// Jackpot amount in dollars, nullable
    int? jackpot,

    /// Timestamp when record was created
    required DateTime createdAt,

    /// Data source ('api' or 'manual')
    @Default('api') String source,
  }) = _Drawing;

  factory Drawing.fromJson(Map<String, dynamic> json) =>
      _$DrawingFromJson(json);
}
