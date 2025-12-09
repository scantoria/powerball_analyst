import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

/// Smoothing level for rolling baseline calculation
enum SmoothingLevel {
  /// Raw recalculation (no smoothing)
  none,

  /// 0.85 previous + 0.15 new
  light,

  /// 0.70 previous + 0.30 new (default)
  normal,

  /// 0.50 previous + 0.50 new
  heavy,
}

/// Sensitivity for pattern shift detection
enum Sensitivity {
  /// ±2.5 std dev (fewer alerts)
  low,

  /// ±2.0 std dev (default)
  normal,

  /// ±1.5 std dev (more alerts)
  high,

  /// User-defined threshold
  custom,
}

/// Display mode for deviation data
enum DisplayMode {
  /// Icons and labels only
  simple,

  /// Numeric scores and detailed stats
  advanced,
}

/// User preferences stored locally
@freezed
class Settings with _$Settings {
  const factory Settings({
    /// Smoothing factor for Bₙ calculation
    @Default(SmoothingLevel.normal) SmoothingLevel smoothingFactor,

    /// Shift detection sensitivity
    @Default(Sensitivity.normal) Sensitivity shiftSensitivity,

    /// Custom threshold (if sensitivity=custom)
    double? customSensitivity,

    /// Deviation display mode
    @Default(DisplayMode.simple) DisplayMode displayMode,

    /// Dark theme enabled
    @Default(false) bool darkMode,

    /// Push notifications enabled
    @Default(true) bool notifications,

    /// Auto-sync on app launch
    @Default(true) bool autoSync,

    /// Last successful sync timestamp
    DateTime? lastSyncAt,

    /// Include baseline history in CSV exports
    @Default(true) bool includeBaselineInExport,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}
