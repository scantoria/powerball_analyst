/// Powerball game constants
class PowerballConstants {
  // Ball ranges
  static const int minWhiteBall = 1;
  static const int maxWhiteBall = 69;
  static const int whiteBallCount = 5;

  static const int minPowerball = 1;
  static const int maxPowerball = 26;

  // Power Play multiplier
  static const int minMultiplier = 2;
  static const int maxMultiplier = 10;

  // Drawing schedule
  static const List<int> drawingDays = [1, 3, 6]; // Monday, Wednesday, Saturday

  // Validation ranges
  static const int minSumTotal = 120;
  static const int maxSumTotal = 180;
  static const int optimalOddCountMin = 2;
  static const int optimalOddCountMax = 3;

  // Baseline configuration
  static const int baselineDrawingCount = 20;
  static const int rollingBaselineRecalcInterval = 5;

  // Hot/Cold thresholds (percentiles)
  static const int hotPercentile = 80; // Top 20%
  static const int coldPercentile = 20; // Bottom 20%

  // Deviation classification thresholds
  static const double hotRisingThreshold = 1.5; // > +1.5 std dev
  static const double warmingMinThreshold = 0.5; // +0.5 to +1.5
  static const double stableMinThreshold = -0.5; // -0.5 to +0.5
  static const double coolingMinThreshold = -1.5; // -1.5 to -0.5
  // cold falling: < -1.5

  // Pattern shift sensitivity defaults
  static const double sensitivityLow = 2.5; // ±2.5 std dev
  static const double sensitivityNormal = 2.0; // ±2.0 std dev
  static const double sensitivityHigh = 1.5; // ±1.5 std dev

  // Auto-pick algorithm weights
  static const double frequencyWeight = 0.6;
  static const double companionWeight = 0.4;

  // Staleness warning threshold (days)
  static const int staleDataThresholdDays = 7;
}
