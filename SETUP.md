# Powerball Analyst - Setup Guide
**Architecture: Hive-Only (No Firebase)**

## Phase 1 Foundation - Completed! ✅

All Phase 1 tasks have been completed:

### ✅ Completed Tasks

1. **Project Structure** - Created complete folder structure following clean architecture
2. **Dependencies** - Configured all required packages in `pubspec.yaml` (Firebase removed)
3. **Data Models** - Created all 7 models with Freezed:
   - Drawing
   - Cycle (with CycleStatus enum)
   - Baseline (with BaselineType, DateRange, Statistics)
   - Pick
   - PatternShift (with ShiftTrigger enum)
   - Settings (with SmoothingLevel, Sensitivity, DisplayMode enums)
   - NumberStats (with BallType, Classification, Trend enums)
4. **Hive Service** - Created HiveService as primary and only data persistence layer
5. **App Initialization** - Updated main.dart and created app.dart (Hive-only)

---

## Next Steps

### 1. Install Dependencies

Run the following command to install all packages:

```bash
flutter pub get
```

### 2. Generate Freezed Code

The models use Freezed for immutability and JSON serialization. Generate the required files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will create:
- `*.freezed.dart` files for each model
- `*.g.dart` files for JSON serialization

### 3. Create Hive Type Adapters

After code generation, you'll need to create Hive adapters for the models. This can be done manually or using `hive_generator`. For now, the models are ready but Hive adapters are commented out in `hive_service.dart`.

**Note:** Hive is the primary and only data persistence layer. No Firebase, no cloud sync needed.

---

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App-wide constants
│   ├── theme/          # Theme configuration
│   ├── utils/          # Utility functions
│   └── extensions/     # Dart extensions
├── data/
│   ├── api/            # API clients
│   ├── repositories/   # Data repositories
│   └── local/          # Local storage (Hive)
├── models/             # Data models (Freezed)
│   ├── drawing.dart
│   ├── cycle.dart
│   ├── baseline.dart
│   ├── pick.dart
│   ├── pattern_shift.dart
│   ├── settings.dart
│   └── number_stats.dart
├── services/
│   ├── analysis/       # Analysis algorithms
│   ├── recommendation/ # Pick generation
│   └── sync/           # Data synchronization
├── providers/          # Riverpod providers
├── ui/
│   ├── screens/        # App screens
│   └── widgets/        # Reusable widgets
├── firebase/
│   └── firebase_options.dart
├── app.dart            # Root app widget
└── main.dart           # App entry point
```

---

## What's Configured

### Dependencies Installed

**Core:**
- flutter_riverpod ^2.4.0 (State management)
- hive_flutter ^1.1.0 (Primary data storage - no Firebase!)

**Networking & Data:**
- dio ^5.4.0 (HTTP client)
- freezed_annotation ^2.4.0 (Immutable models)
- json_annotation ^4.8.0 (JSON serialization)

**UI:**
- fl_chart ^0.65.0 (Charts)
- go_router ^12.0.0 (Navigation)

**Utilities:**
- intl ^0.18.0 (Internationalization)
- csv ^5.0.0 (CSV export)
- uuid ^4.0.0 (ID generation)

**Dev Dependencies:**
- build_runner ^2.4.0
- freezed ^2.4.0
- json_serializable ^6.7.0
- mockito ^5.4.0
- flutter_lints ^6.0.0

---

## Models Overview

### Drawing
Represents a single Powerball lottery drawing with white balls, powerball, multiplier, and jackpot.

### Cycle
Manages pattern cycles with three statuses: collecting (Phase 1), active (Phase 2), and closed.

### Baseline
Statistical snapshot supporting three types:
- **B₀** (Initial): First 20 drawings, locked permanently
- **Bₙ** (Rolling): Last 20 drawings, recalculated every 5
- **Bₚ** (Preliminary): Temporary baseline during Phase 1

### Pick
User number selection with validation data (sum, odd count, match results).

### PatternShift
Records detected pattern shifts with 5 trigger types:
- Long-term Drift
- Short-term Surge
- Baseline Divergence
- Correlation Breakdown
- New Dominance

### Settings
User preferences including smoothing factor, sensitivity, display mode, and theme.

### NumberStats
Computed statistics for individual numbers (not persisted, calculated on-demand).

---

## Running the App

After completing steps 1-2 above, you can run the app:

```bash
flutter run
```

You should see a splash screen with "Foundation Setup Complete".

---

## What's Next?

According to the project plan, the next phase includes:

**Phase 2: Core Features (52 hours)**
- NY Open Data API client
- Repositories (Drawing, Cycle, Baseline, Pick)
- Data sync service
- All 5 main screens + Baseline Comparison screen
- Shared widgets

**Phase 3: Analysis Engine (48 hours)**
- Frequency analyzer
- Co-occurrence analyzer
- Baseline calculator
- Deviation calculator
- Pattern shift detector
- Pick generator (auto-pick algorithm)
- Validation service

**Phase 4: Polish & Deploy (35 hours)**
- Unit & widget tests
- Performance optimization
- App icon & splash screen
- Build configuration
- Beta deployment

---

## Troubleshooting

### Code Generation Errors
If you encounter errors during code generation, ensure:
1. All imports are correct
2. Freezed and json_serializable are the latest compatible versions
3. Run with `--delete-conflicting-outputs` flag

### Hive Errors
If Hive boxes fail to open:
1. Check that HiveService.init() is called before runApp()
2. Ensure write permissions in the app directory

---

## Documentation

All project documentation is available in `/docs`:
- Powerball_Analyst_UI_Wireframes_v1.1.md
- Powerball_Analyst_Requirements_Design_v1.1.md
- Powerball_Analyst_Folder_Structure.md
- Powerball_Analyst_Data_Schema.md
- Powerball_Analyst_Data_Flow.md
- Powerball_Analyst_Project_Plan_v1.1.md

---

## Notes

- **No Firebase** - Removed to simplify architecture for personal single-user app
- **Hive-Only Storage** - All data persisted locally (~100KB/year)
- **Backup via Export** - CSV/JSON export for manual backup
- Hive adapters need to be generated/registered for full local storage support
- All models are ready for code generation
- Theme colors follow the design spec (Primary Blue #1E3A5F, Powerball Red #E63946, etc.)
- **Data Flow:** NY Open Data API → Hive → UI (simplified!)

Ready to proceed with Phase 2! 🚀
