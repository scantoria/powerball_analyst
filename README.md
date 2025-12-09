# Powerball Analyst

A Flutter application for analyzing Powerball lottery patterns using a three-baseline statistical system.

## Overview

Powerball Analyst is a personal beta app that helps analyze historical Powerball drawing data to identify patterns, trends, and generate informed number picks. The app uses a sophisticated three-baseline system (B₀, Bₙ, Bₚ) to detect pattern shifts and provide statistical insights.

## Key Features

- **Three-Baseline System**: Initial (B₀), Rolling (Bₙ), and Preliminary (Bₚ) baselines for comprehensive analysis
- **Two-Phase Cycle Management**: Collecting phase (drawings 1-20) and Active phase (drawings 21+)
- **Pattern Shift Detection**: Five trigger types to identify significant changes in drawing patterns
- **Frequency Analysis**: Track hot, warm, stable, cool, and cold numbers
- **Co-occurrence Analysis**: Identify number pairs that frequently appear together
- **Auto-Pick Generation**: Algorithm-based number selection using statistical insights
- **Offline-First**: Full functionality without internet (except for data syncing)
- **Dark Mode**: Complete light and dark theme support

## Architecture

This app uses a **Hive-only architecture** (no Firebase) for simplicity and offline-first capability:

- **Data Flow**: NY Open Data API → Hive → UI
- **State Management**: Riverpod
- **Local Storage**: Hive (primary and only persistence layer)
- **Navigation**: go_router with bottom navigation
- **Design**: Material 3 with custom theme

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture decisions.

## Project Structure

```
lib/
├── core/               # Constants, theme, utilities
├── data/               # Data layer (API, repositories, local storage)
├── models/             # Freezed data models
├── providers/          # Riverpod providers
├── services/           # Business logic services
└── ui/                 # Screens, widgets, navigation
```

See [docs/Powerball_Analyst_Folder_Structure.md](docs/Powerball_Analyst_Folder_Structure.md) for complete structure.

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd powerball_analyst
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Generate Freezed models:
   ```bash
   flutter pub run build_runner build
   ```

4. Run the app:
   ```bash
   flutter run
   ```

See [SETUP.md](SETUP.md) for detailed setup instructions.

## Development Status

### ✅ Completed (Phase 1 & 2)
- Project structure and dependencies
- 7 Freezed models (Drawing, Cycle, Baseline, Pick, PatternShift, Settings, NumberStats)
- Hive service with export/import functionality
- NY Lottery API client
- 4 repositories (Drawing, Cycle, Baseline, Pick)
- Data sync service
- Riverpod providers
- UI foundation (4 shared widgets, 7 screen scaffolds)
- Navigation system with bottom nav
- Material 3 theme (light/dark modes)

### 🚧 In Progress (Phase 3)
- Analysis engine (FrequencyAnalyzer, CooccurrenceAnalyzer, BaselineCalculator)
- Pattern shift detection
- Pick generation algorithm
- Deviation calculation

### 📋 Planned (Phase 4)
- Unit and widget tests
- Integration testing
- Performance optimization
- App icon and splash screen
- Beta deployment

## Documentation

- [Requirements & Design](docs/Powerball_Analyst_Requirements_Design_v1.1.md)
- [Data Flow](docs/Powerball_Analyst_Data_Flow.md)
- [Data Schema](docs/Powerball_Analyst_Data_Schema.md)
- [UI Wireframes](docs/Powerball_Analyst_UI_Wireframes_v1.1.md)
- [Project Plan](docs/Powerball_Analyst_Project_Plan_v1.1.md)

## Data Source

Drawing data is fetched from the [New York State Lottery Powerball Winning Numbers API](https://data.ny.gov/resource/d6yy-54nr.json).

## License

Personal project - not for distribution.

## Disclaimer

This app is for educational and entertainment purposes only. It does not guarantee winning numbers. Lottery games are games of chance.
