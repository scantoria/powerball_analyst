# Powerball Analyst
# Folder Structure & Design Patterns
**Version 1.0 - December 2025**

---

## 1. Architecture Overview

The Powerball Analyst app follows a clean architecture approach with clear separation of concerns. This structure supports testability, maintainability, and scalability.

### 1.1 Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Screens   │  │   Widgets   │  │  State (Riverpod)   │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                      DOMAIN LAYER                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   Models    │  │  Services   │  │  Analysis Engine    │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                       DATA LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Repositories│  │  API Client │  │  Local Cache (Hive) │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    EXTERNAL SERVICES                        │
│  ┌─────────────────────────┐  ┌───────────────────────────┐│
│  │  NY Open Data API       │  │  Firebase Firestore       ││
│  └─────────────────────────┘  └───────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Design Principles

- **Single Responsibility:** Each class/file has one clear purpose
- **Dependency Inversion:** High-level modules don't depend on low-level modules
- **Repository Pattern:** Abstract data sources behind repositories
- **Provider Pattern:** Use Riverpod for dependency injection and state
- **Feature-First Organization:** Group by feature, not by type

---

## 2. Project Folder Structure

```
powerball_analyst/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # MaterialApp config
│   │
│   ├── core/                        # Core utilities
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── powerball_constants.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── dark_theme.dart
│   │   ├── utils/
│   │   │   ├── date_utils.dart
│   │   │   ├── number_utils.dart
│   │   │   └── validators.dart
│   │   └── extensions/
│   │       ├── datetime_extensions.dart
│   │       └── list_extensions.dart
│   │
│   ├── data/                        # Data layer
│   │   ├── api/
│   │   │   ├── ny_lottery_api.dart
│   │   │   └── api_exceptions.dart
│   │   ├── repositories/
│   │   │   ├── drawing_repository.dart
│   │   │   ├── cycle_repository.dart
│   │   │   ├── pick_repository.dart
│   │   │   └── baseline_repository.dart
│   │   └── local/
│   │       ├── hive_service.dart
│   │       └── cache_manager.dart
│   │
│   ├── models/                      # Domain models
│   │   ├── drawing.dart
│   │   ├── cycle.dart
│   │   ├── pick.dart
│   │   ├── baseline.dart
│   │   ├── number_stats.dart
│   │   └── pattern_shift.dart
│   │
│   ├── services/                    # Business logic
│   │   ├── analysis/
│   │   │   ├── frequency_analyzer.dart
│   │   │   ├── cooccurrence_analyzer.dart
│   │   │   ├── baseline_calculator.dart
│   │   │   ├── deviation_calculator.dart
│   │   │   └── pattern_shift_detector.dart
│   │   ├── recommendation/
│   │   │   ├── pick_generator.dart
│   │   │   └── validation_service.dart
│   │   └── sync/
│   │       └── data_sync_service.dart
│   │
│   ├── providers/                   # Riverpod providers
│   │   ├── drawing_providers.dart
│   │   ├── cycle_providers.dart
│   │   ├── analysis_providers.dart
│   │   ├── baseline_providers.dart
│   │   ├── pick_providers.dart
│   │   └── settings_providers.dart
│   │
│   ├── ui/                          # Presentation layer
│   │   ├── screens/
│   │   │   ├── dashboard/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   └── widgets/
│   │   │   ├── analysis/
│   │   │   │   ├── analysis_screen.dart
│   │   │   │   └── widgets/
│   │   │   ├── picker/
│   │   │   │   ├── picker_screen.dart
│   │   │   │   └── widgets/
│   │   │   ├── cycles/
│   │   │   │   ├── cycles_screen.dart
│   │   │   │   ├── baseline_comparison_screen.dart
│   │   │   │   └── widgets/
│   │   │   ├── history/
│   │   │   │   ├── history_screen.dart
│   │   │   │   └── widgets/
│   │   │   └── settings/
│   │   │       └── settings_screen.dart
│   │   ├── widgets/                  # Shared widgets
│   │   │   ├── number_ball.dart
│   │   │   ├── heat_map_grid.dart
│   │   │   ├── deviation_indicator.dart
│   │   │   ├── baseline_progress.dart
│   │   │   └── countdown_timer.dart
│   │   └── navigation/
│   │       └── app_navigation.dart
│   │
│   └── firebase/                    # Firebase config
│       └── firebase_options.dart
│
├── test/                            # Unit & widget tests
├── assets/                          # Images, fonts
├── pubspec.yaml                     # Dependencies
└── README.md
```

---

## 3. Key Component Details

### 3.1 Models

| Model | Purpose & Key Fields |
|-------|---------------------|
| Drawing | Lottery drawing result: id, drawDate, whiteBalls (List<int>), powerball, jackpot |
| Cycle | Pattern cycle: id, startDate, endDate, status (collecting/active/closed), drawingCount, initialBaseline, rollingBaseline, notes |
| Baseline | Analysis snapshot: drawingRange, whiteballFrequency (Map), powerballFrequency (Map), cooccurrenceMatrix, hotNumbers, coldNumbers, neverDrawn, statistics (mean, stdDev) |
| Pick | User selection: id, whiteBalls, powerball, targetDrawDate, createdAt, isAutoPick, matchCount, isPreliminary |
| NumberStats | Per-number analysis: number, frequency, deviation, classification (hot/warm/stable/cool/cold), lastDrawn, avgGap, companions |
| PatternShift | Shift alert: triggerType, detectedAt, details, isDismissed, triggeredNewCycle |

### 3.2 Repositories

- **DrawingRepository:** CRUD for drawings, sync with API, query by date range
- **CycleRepository:** Manage cycles, create/close cycles, get current cycle
- **BaselineRepository:** Store/retrieve baselines, baseline history
- **PickRepository:** Save picks, match against results, performance stats

### 3.3 Services (Analysis Engine)

- **FrequencyAnalyzer:** Calculate frequency for all numbers in a drawing set
- **CooccurrenceAnalyzer:** Build pair matrix, identify companions
- **BaselineCalculator:** Generate B₀, Bₚ, Bₙ with smoothing options
- **DeviationCalculator:** Compute deviation scores, classify numbers
- **PatternShiftDetector:** Monitor triggers, generate alerts
- **PickGenerator:** Auto-pick algorithm implementation
- **ValidationService:** Sum range, odd/even, never-drawn checks

---

## 4. State Management (Riverpod)

### 4.1 Provider Types

| Type | Use Case | Example |
|------|----------|---------|
| Provider | Immutable values | Constants, repository instances |
| StateProvider | Simple mutable state | Selected tab, display mode toggle |
| FutureProvider | Async data fetch | API calls, one-time loads |
| StreamProvider | Real-time streams | Firestore listeners |
| NotifierProvider | Complex state logic | Cycle state, pick selection |

### 4.2 Key Providers

```dart
// drawing_providers.dart
final drawingRepositoryProvider = Provider((ref) => DrawingRepository());
final drawingsProvider = StreamProvider((ref) =>
  ref.watch(drawingRepositoryProvider).watchDrawings());
final latestDrawingProvider = FutureProvider((ref) =>
  ref.watch(drawingRepositoryProvider).getLatest());

// cycle_providers.dart
final currentCycleProvider = StreamProvider((ref) =>
  ref.watch(cycleRepositoryProvider).watchCurrentCycle());
final cyclePhaseProvider = Provider((ref) {
  final cycle = ref.watch(currentCycleProvider).value;
  return cycle?.drawingCount >= 20 ? Phase.active : Phase.collecting;
});

// baseline_providers.dart
final activeBaselineProvider = Provider((ref) {
  final phase = ref.watch(cyclePhaseProvider);
  final cycle = ref.watch(currentCycleProvider).value;
  return phase == Phase.active ? cycle?.rollingBaseline : cycle?.preliminaryBaseline;
});
final overlapScoreProvider = Provider((ref) {
  final b0 = ref.watch(initialBaselineProvider);
  final bn = ref.watch(rollingBaselineProvider);
  return calculateOverlap(b0?.hotNumbers, bn?.hotNumbers);
});
```

---

## 5. Coding Standards

### 5.1 Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Files | snake_case.dart | drawing_repository.dart |
| Classes | PascalCase | DrawingRepository |
| Variables | camelCase | drawingCount |
| Constants | camelCase or SCREAMING_SNAKE | maxWhiteBall, MAX_WHITE_BALL |
| Providers | camelCaseProvider | currentCycleProvider |
| Screens | FeatureScreen | DashboardScreen |
| Widgets | DescriptiveName | NumberBall, HeatMapGrid |

### 5.2 File Organization Rules

- One class per file (exceptions: small related classes)
- Imports ordered: dart, flutter, packages, local (with blank lines between)
- Screen-specific widgets go in screen's widgets/ subfolder
- Shared widgets go in ui/widgets/
- Keep files under 300 lines; extract if larger
- Use barrel files (index.dart) for feature exports

### 5.3 Code Style

- Use trailing commas for better formatting
- Prefer const constructors where possible
- Use named parameters for 3+ arguments
- Document public APIs with /// comments
- Use extension methods for common operations

---

## 6. Dependencies (pubspec.yaml)

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.4.0 | State management |
| firebase_core | ^2.24.0 | Firebase initialization |
| cloud_firestore | ^4.13.0 | Database |
| hive_flutter | ^1.1.0 | Local caching |
| dio | ^5.4.0 | HTTP client |
| fl_chart | ^0.65.0 | Charts and visualizations |
| freezed_annotation | ^2.4.0 | Immutable models |
| json_annotation | ^4.8.0 | JSON serialization |
| go_router | ^12.0.0 | Navigation |
| intl | ^0.18.0 | Date formatting |
| csv | ^5.0.0 | CSV export |

**Dev Dependencies:**
- build_runner, freezed, json_serializable (code generation)
- flutter_test, mockito, fake_cloud_firestore (testing)
- flutter_lints (code quality)

---

## 7. Document Status

| # | Document | Status | Notes |
|---|----------|--------|-------|
| 1 | UI Wireframes | v1.1 Complete | |
| 2 | Project Plan | v1.0 Complete | |
| 3 | Requirements & Design | v1.1 Complete | |
| 4 | Folder Structure & Patterns | v1.0 Complete | This document |
| 5 | Data Flow | Next | |
| 6 | Data Structure & Schema | Pending | |

---

## 8. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 5, 2025 | Project Owner | Initial folder structure and design patterns |
