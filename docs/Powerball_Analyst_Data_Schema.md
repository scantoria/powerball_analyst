# Powerball Analyst
# Data Structure & Schema
**Version 2.0 - December 2025**
**Architecture: Hive-Only (No Firebase)**

---

## 1. Data Model Overview

This document defines all data structures used in the Powerball Analyst application, including Dart model classes and Hive type adapters.

**Storage Architecture:** All data is persisted locally using Hive. No Firebase, no cloud sync.

### 1.1 Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   Drawing   │       │    Cycle    │       │   Baseline  │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id          │       │ id          │◀──┐   │ id          │
│ drawDate    │       │ startDate   │   │   │ cycleId     │
│ whiteBalls  │       │ endDate     │   │   │ type        │
│ powerball   │       │ status      │   │   │ drawingRange│
│ multiplier  │       │ drawingCount│   │   │ frequencies │
└──────┬──────┘       │ initialBase─┼───┼──▶│ cooccurrence│
       │              │ rollingBase─┼───┘   │ hotNumbers  │
       │              │ prelimBase──┼──────▶│ statistics  │
       │              └──────┬──────┘       └─────────────┘
       │                     │
       │    ┌────────────────┘
       │    │
       ▼    ▼
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│    Pick     │       │ PatternShift│       │ NumberStats │
├─────────────┤       ├─────────────┤       ├─────────────┤
│ id          │       │ id          │       │ number      │
│ cycleId     │       │ cycleId     │       │ frequency   │
│ whiteBalls  │       │ triggerType │       │ deviation   │
│ powerball   │       │ detectedAt  │       │ classification
│ targetDate  │       │ details     │       │ lastDrawn   │
│ matchCount  │       │ isDismissed │       │ companions  │
└─────────────┘       └─────────────┘       └─────────────┘
```

---

## 2. Drawing Model

Represents a single Powerball lottery drawing result.

| Field | Type | Req | Description |
|-------|------|-----|-------------|
| id | String | ✓ | Unique identifier (format: 'drawing_YYYYMMDD') |
| drawDate | DateTime | ✓ | Date of the drawing |
| whiteBalls | List<int> | ✓ | 5 white ball numbers (1-69), sorted ascending |
| powerball | int | ✓ | Powerball number (1-26) |
| multiplier | int? | | Power Play multiplier (2-10), nullable |
| jackpot | int? | | Jackpot amount in dollars, nullable |
| createdAt | DateTime | ✓ | Timestamp when record was created |
| source | String | ✓ | Data source ('api' or 'manual') |

**Dart Model:**
```dart
@freezed
class Drawing with _$Drawing {
  const factory Drawing({
    required String id,
    required DateTime drawDate,
    required List<int> whiteBalls,
    required int powerball,
    int? multiplier,
    int? jackpot,
    required DateTime createdAt,
    @Default('api') String source,
  }) = _Drawing;

  factory Drawing.fromJson(Map<String, dynamic> json) =>
      _$DrawingFromJson(json);
}
```

**Hive Box:** `drawingsBox`
**Hive Type ID:** 0

---

## 3. Cycle Model

Represents a pattern cycle period for analysis. A cycle contains drawings, baselines, and metadata about the current analysis phase.

| Field | Type | Req | Description |
|-------|------|-----|-------------|
| id | String | ✓ | Unique identifier (UUID) |
| name | String? | | Optional user-defined name |
| startDate | DateTime | ✓ | Cycle start date |
| endDate | DateTime? | | Cycle end date (null if active) |
| status | CycleStatus | ✓ | collecting \| active \| closed |
| drawingCount | int | ✓ | Number of drawings in cycle |
| initialBaselineId | String? | | Reference to B₀ baseline |
| rollingBaselineId | String? | | Reference to current Bₙ |
| prelimBaselineId | String? | | Reference to Bₚ (Phase 1 only) |
| notes | String? | | User notes about this cycle |
| createdAt | DateTime | ✓ | Timestamp when created |
| closedAt | DateTime? | | Timestamp when closed |

**CycleStatus Enum:**

| Value | Description |
|-------|-------------|
| collecting | Phase 1: Building baseline (drawings 1-20) |
| active | Phase 2: Active analysis with locked B₀ |
| closed | Cycle ended, archived for history |

**Hive Box:** `cyclesBox`
**Hive Type ID:** 1

---

## 4. Baseline Model

Represents a computed statistical snapshot of drawing data. Three types exist: B₀ (initial), Bₙ (rolling), and Bₚ (preliminary).

| Field | Type | Req | Description |
|-------|------|-----|-------------|
| id | String | ✓ | Unique identifier (UUID) |
| cycleId | String | ✓ | Parent cycle reference |
| type | BaselineType | ✓ | initial \| rolling \| preliminary |
| drawingRange | DateRange | ✓ | Start and end dates of drawings |
| drawingCount | int | ✓ | Number of drawings analyzed |
| whiteballFreq | Map<int,int> | ✓ | Frequency map for balls 1-69 |
| powerballFreq | Map<int,int> | ✓ | Frequency map for balls 1-26 |
| cooccurrence | Map<String,int> | ✓ | Pair frequency (key: '12-34') |
| hotWhiteballs | List<int> | ✓ | Top 20% white balls |
| coldWhiteballs | List<int> | ✓ | Bottom 20% white balls |
| neverDrawnWB | List<int> | ✓ | White balls with 0 frequency |
| hotPowerballs | List<int> | ✓ | Top 20% Powerballs |
| neverDrawnPB | List<int> | ✓ | Powerballs with 0 frequency |
| statistics | Statistics | ✓ | Mean, stdDev, median |
| smoothingFactor | double? | | Applied smoothing (for Bₙ) |
| createdAt | DateTime | ✓ | Calculation timestamp |

**Statistics Sub-Model:**

| Field | Type | Req | Description |
|-------|------|-----|-------------|
| mean | double | ✓ | Average frequency |
| stdDev | double | ✓ | Standard deviation |
| median | double | ✓ | Median frequency |
| min | int | ✓ | Minimum frequency |
| max | int | ✓ | Maximum frequency |

**Hive Box:** `baselinesBox`
**Hive Type ID:** 2

---

## 5. Pick Model

Represents a user's number selection for a specific drawing.

| Field | Type | Req | Description |
|-------|------|-----|-------------|
| id | String | ✓ | Unique identifier (UUID) |
| cycleId | String | ✓ | Parent cycle reference |
| whiteBalls | List<int> | ✓ | 5 selected white balls (1-69) |
| powerball | int | ✓ | Selected Powerball (1-26) |
| targetDrawDate | DateTime | ✓ | Target drawing date |
| isAutoPick | bool | ✓ | True if auto-generated |
| isPreliminary | bool | ✓ | True if created during Phase 1 |
| matchCount | int? | | Matches after drawing (0-6) |
| powerballMatch | bool? | | Powerball matched? |
| sumTotal | int | ✓ | Sum of white balls |
| oddCount | int | ✓ | Count of odd numbers |
| explanation | String? | | Auto-pick reasoning |
| createdAt | DateTime | ✓ | Selection timestamp |
| evaluatedAt | DateTime? | | When matched against result |

**Hive Box:** `picksBox`
**Hive Type ID:** 3

---

## 6. PatternShift Model

Records detected pattern shifts that may indicate a cycle change.

| Field | Type | Req | Description |
|-------|------|-----|-------------|
| id | String | ✓ | Unique identifier (UUID) |
| cycleId | String | ✓ | Parent cycle reference |
| triggerType | ShiftTrigger | ✓ | Type of shift detected |
| detectedAt | DateTime | ✓ | Detection timestamp |
| drawingId | String | ✓ | Drawing that triggered shift |
| severity | String | ✓ | low \| medium \| high |
| details | Map<String,dynamic> | ✓ | Trigger-specific data |
| isDismissed | bool | ✓ | User dismissed alert |
| dismissedAt | DateTime? | | Dismissal timestamp |
| triggeredNewCycle | bool | ✓ | Led to new cycle creation |

**ShiftTrigger Enum:**

| Value | Description |
|-------|-------------|
| longTermDrift | 5+ B₀ hot numbers now below average |
| shortTermSurge | 3+ numbers jump > +2.0 dev in 5 drawings |
| baselineDivergence | B₀ and Bₙ hot sets differ > 50% |
| correlationBreakdown | Top 5 B₀ pairs no longer co-occurring |
| newDominance | Non-B₀-top-30% number is now #1 or #2 |

**Hive Box:** `shiftsBox`
**Hive Type ID:** 4

---

## 7. NumberStats Model

Computed statistics for a single number within a baseline. Used for display and analysis but not persisted directly.

| Field | Type | Req | Description |
|-------|------|-----|-------------|
| number | int | ✓ | The ball number (1-69 or 1-26) |
| ballType | BallType | ✓ | white \| powerball |
| frequency | int | ✓ | Times drawn in range |
| expectedFreq | double | ✓ | Statistical expected frequency |
| deviation | double | ✓ | Standard deviations from mean |
| percentile | int | ✓ | Percentile rank (1-100) |
| classification | Classification | ✓ | hot \| warm \| stable \| cool \| cold |
| lastDrawnDate | DateTime? | | Most recent appearance |
| drawingsSince | int | ✓ | Drawings since last appearance |
| avgGap | double | ✓ | Average gap between appearances |
| companions | List<int> | ✓ | Top 5 co-occurring numbers |
| trend | Trend | ✓ | rising \| stable \| falling |

**Classification Enum:**

| Value | Deviation Range | Display |
|-------|----------------|---------|
| hot | > +1.5 | ↑↑ Hot Rising (Red) |
| warm | +0.5 to +1.5 | ↑ Warming (Orange) |
| stable | -0.5 to +0.5 | ● Stable (Green) |
| cool | -1.5 to -0.5 | ↓ Cooling (Light Blue) |
| cold | < -1.5 | ↓↓ Cold Falling (Blue) |

**Note:** NumberStats is computed at runtime from Baseline data and not persisted to Hive (ephemeral).

---

## 8. Settings Model

User preferences stored locally in Hive.

| Field | Type | Req | Description |
|-------|------|-----|-------------|
| smoothingFactor | SmoothingLevel | ✓ | none \| light \| normal \| heavy |
| shiftSensitivity | Sensitivity | ✓ | low \| normal \| high \| custom |
| customSensitivity | double? | | Custom threshold (if sensitivity=custom) |
| displayMode | DisplayMode | ✓ | simple \| advanced |
| darkMode | bool | ✓ | Dark theme enabled |
| notifications | bool | ✓ | Push notifications enabled |
| autoSync | bool | ✓ | Auto-sync on app launch |
| lastSyncAt | DateTime? | | Last successful sync timestamp |

**SmoothingLevel Values:**

| Value | Weight | Formula |
|-------|--------|---------|
| none | 0.0 | Bₙ = Latest 20 drawings (raw) |
| light | 0.85 | Bₙ = 0.85 × prev + 0.15 × new |
| normal | 0.70 | Bₙ = 0.70 × prev + 0.30 × new (default) |
| heavy | 0.50 | Bₙ = 0.50 × prev + 0.50 × new |

**Hive Box:** `settingsBox`
**Hive Type ID:** 5

---

## 9. Hive Storage Structure

All data is stored locally in Hive boxes. Each box contains a flat key-value store.

```
Hive Local Storage
│
├── drawingsBox                 # All lottery drawing results
│   ├── key: drawingId (String)
│   └── value: Drawing object
│
├── cyclesBox                   # Pattern cycles
│   ├── key: cycleId (String)
│   └── value: Cycle object
│
├── baselinesBox                # Statistical snapshots (B₀, Bₙ, history)
│   ├── key: baselineId (String)
│   └── value: Baseline object
│
├── picksBox                    # User number selections
│   ├── key: pickId (String)
│   └── value: Pick object
│
├── shiftsBox                   # Pattern shift alerts
│   ├── key: shiftId (String)
│   └── value: PatternShift object
│
├── settingsBox                 # User preferences
│   ├── key: setting name (String)
│   └── value: dynamic
│
└── metadataBox                 # App metadata
    ├── key: 'lastSyncAt'       # Last API sync timestamp
    ├── key: 'appVersion'       # Current app version
    └── key: 'migrationFlag'    # Migration status flags
```

### 9.1 Querying & Indexing

Hive boxes support:
- **Direct key lookup:** `box.get(key)` - O(1)
- **Iteration:** `box.values` - for filtering and sorting in-memory
- **Watch streams:** `box.watch()` - for reactive updates

**Note:** No built-in indexing. For complex queries, use in-memory filtering or maintain custom index maps.

---

## 10. Hive Type Adapter Summary

| Type ID | Model | Box Name | Adapter Class |
|---------|-------|----------|---------------|
| 0 | Drawing | drawingsBox | DrawingAdapter |
| 1 | Cycle | cyclesBox | CycleAdapter |
| 2 | Baseline | baselinesBox | BaselineAdapter |
| 3 | Pick | picksBox | PickAdapter |
| 4 | PatternShift | shiftsBox | PatternShiftAdapter |
| 5 | Settings | settingsBox | SettingsAdapter |
| 10 | CycleStatus (enum) | — | CycleStatusAdapter |
| 11 | BaselineType (enum) | — | BaselineTypeAdapter |
| 12 | ShiftTrigger (enum) | — | ShiftTriggerAdapter |

### 10.1 Hive Initialization

```dart
Future<void> initHive() async {
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(DrawingAdapter());
  Hive.registerAdapter(CycleAdapter());
  Hive.registerAdapter(BaselineAdapter());
  Hive.registerAdapter(PickAdapter());
  Hive.registerAdapter(PatternShiftAdapter());
  Hive.registerAdapter(SettingsAdapter());
  Hive.registerAdapter(CycleStatusAdapter());
  Hive.registerAdapter(BaselineTypeAdapter());
  Hive.registerAdapter(ShiftTriggerAdapter());

  // Open boxes
  await Hive.openBox<Drawing>('drawingsBox');
  await Hive.openBox<Cycle>('cyclesBox');
  await Hive.openBox<Baseline>('baselinesBox');
  await Hive.openBox<Pick>('picksBox');
  await Hive.openBox<PatternShift>('shiftsBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('metadataBox');
}
```

---

## 11. Validation Rules

### 11.1 Drawing Validation

- whiteBalls must contain exactly 5 unique integers
- Each whiteBall must be 1-69 inclusive
- powerball must be 1-26 inclusive
- multiplier (if present) must be 2-10 inclusive
- drawDate must be Mon, Wed, or Sat

### 11.2 Pick Validation

- Same rules as Drawing for ball numbers
- sumTotal (sum of whiteBalls) should be 120-180 for warning
- oddCount should be 2-3 for optimal distribution
- targetDrawDate must be future date
- Never-drawn numbers trigger warning (not error)

### 11.3 Cycle Validation

- Only one cycle with status='collecting' or 'active' at a time
- endDate must be after startDate
- initialBaselineId required when status='active'

---

## 12. Document Status

| # | Document | Status | Notes |
|---|----------|--------|-------|
| 1 | UI Wireframes | v1.1 Complete | |
| 2 | Project Plan | v1.0 Complete | |
| 3 | Requirements & Design | v1.1 Complete | |
| 4 | Folder Structure & Patterns | v1.0 Complete | |
| 5 | Data Flow | v1.0 Complete | |
| 6 | Data Structure & Schema | v1.0 Complete | This document |

---

## 13. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 5, 2025 | Project Owner | Initial data structure and schema documentation |
| 2.0 | Dec 8, 2025 | Project Owner | Removed Firebase, Hive-only architecture |
