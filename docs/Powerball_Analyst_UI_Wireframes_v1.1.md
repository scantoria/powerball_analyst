# Powerball Analyst
# UI Wireframes & Screen Specifications
**Version 1.1 Beta**
**December 2025**

## Updates in v1.1:
- Added Baseline Comparison Screen (Section 3.7)
- Updated Settings Screen with Algorithm Options (Section 3.6)
- Updated Dashboard for Baseline Phase Display (Section 3.1)

---

## 1. Document Overview

This document provides comprehensive UI wireframes and screen specifications for the Powerball Analyst mobile application. The app enables users to analyze Powerball lottery data, track patterns across cycles, and generate informed number selections based on historical analysis.

### 1.1 Design Philosophy

The UI design prioritizes clarity, data visualization, and ease of use. Key principles include:
- Clean, distraction-free interface focused on number analysis
- Visual heat maps and charts for quick pattern recognition
- Baseline-aware displays showing phase status and deviation metrics
- Simple/Advanced toggle for deviation display preferences
- Dark mode support for extended usage comfort

### 1.2 Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Blue | #1E3A5F | Headers, navigation, primary actions |
| Powerball Red | #E63946 | Powerball highlights, hot indicators, rising |
| Accent Orange | #F4A261 | Warnings, warming indicators, alerts |
| Success Green | #2A9D8F | Confirmations, stable indicators |
| Cold Blue | #A8DADC | Cold/cooling indicators, falling |

---

## 2. Navigation Structure

The app uses a bottom navigation bar with five primary destinations, plus a Baseline Comparison view accessible from Cycles and Analysis screens.

### 2.1 Bottom Navigation Tabs

- **Dashboard** (Home icon) - Overview, baseline status, quick stats
- **Analysis** (Chart icon) - Frequency, patterns, deviation display
- **Picker** (Target icon) - Number selection and recommendations
- **Cycles** (Calendar icon) - Cycle management, baseline comparison
- **History** (Clock icon) - Pick tracking and results

### 2.2 Navigation Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      APP SHELL                              │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐│
│  │Dashboard│ │Analysis │ │ Picker  │ │ Cycles  │ │History ││
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └───┬────┘│
│       │          │          │          │          │       │
│       ▼          ▼          ▼          ▼          ▼       │
│  [Baseline]  [Heat Map] [Manual]  [New Cycle] [Results]   │
│  [Status]    [Deviations][Auto]   [Compare]   [Stats]     │
│  [Hot/Cold]  [Trends]   [Save]    [Alerts]    [Export]    │
│                  │                   │                    │
│                  └───────┬───────────┘                    │
│                          ▼                                │
│               [Baseline Comparison]                       │
│                  (B₀ vs Bₙ View)                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Screen Specifications

### 3.1 Dashboard Screen

**Purpose:** Provide at-a-glance overview of baseline status, current cycle, upcoming drawings, and key statistics.

#### Phase 1: Building Baseline (Drawings 1-20)

```
┌────────────────────────────────────┐
│         POWERBALL ANALYST          │
├────────────────────────────────────┤
│                                    │
│   ⏳ BUILDING BASELINE...          │
│   ████████████░░░░░░  12/20        │
│   Next recalc: 3 drawings          │
│                                    │
│   ┌──────────────────────────┐    │
│   │    NEXT DRAWING          │    │
│   │    Wednesday, Dec 10     │    │
│   │    Est. Jackpot: $285M   │    │
│   └──────────────────────────┘    │
│                                    │
│   PRELIMINARY HOT NUMBERS          │
│   🔴 21  32  45  07  18            │
│   (Based on 12 drawings)           │
│                                    │
│   NEVER DRAWN (this cycle)         │
│   ⚪ 03  17  29  58  62  67        │
│                                    │
│   [Full analysis after 20 draws]  │
│                                    │
├────────────────────────────────────┤
│  🏠    📊    🎯    📅    🕐      │
└────────────────────────────────────┘
```

#### Phase 2: Active Analysis (Drawings 21+)

```
┌────────────────────────────────────┐
│         POWERBALL ANALYST          │
├────────────────────────────────────┤
│                                    │
│   ✓ BASELINE ACTIVE                │
│   Drawings: 47  │  Overlap: 72%   │
│   [Compare Baselines]              │
│                                    │
│   ┌──────────────────────────┐    │
│   │    NEXT DRAWING          │    │
│   │    Wednesday, Dec 10     │    │
│   │    ⏱️ 2d 14h 32m         │    │
│   └──────────────────────────┘    │
│                                    │
│   HOT NUMBERS      TREND          │
│   🔴 21 ↑↑  32 ●  45 ↓  07 ↑     │
│   🔴 18 ↑   12 ↑↑ (NEW HOT)      │
│                                    │
│   NEVER DRAWN      DROPPED        │
│   ⚪ 03  17  58    🧊 55 (was hot)│
│                                    │
├────────────────────────────────────┤
│  🏠    📊    🎯    📅    🕐      │
└────────────────────────────────────┘
```

#### Dashboard Components

- **Baseline Status Bar:** Shows phase (Building/Active), progress, overlap score, link to comparison
- **Next Drawing Card:** Countdown timer, date, estimated jackpot
- **Hot Numbers with Trend:** Top numbers with deviation indicators (↑↑ Rising, ↑ Warming, ● Stable, ↓ Cooling, ↓↓ Falling)
- **Never Drawn:** Numbers with zero appearances in cycle
- **Dropped Alerts:** Numbers that were hot in B₀ but have fallen significantly

---

### 3.2 Analysis Screen

**Purpose:** Deep-dive into number frequency, patterns, and deviation data. Now includes Simple/Advanced toggle for deviation display.

#### Deviation Display Modes

| Simple Mode | Advanced Mode |
|-------------|---------------|
| Number: 21<br>Status: 🔥 Hot Rising<br>Trend: ↑↑<br><br>Companions: 32, 07, 45 | Number: 21<br>Deviation: +1.82<br>B₀ Frequency: 8<br>Bₙ Frequency: 11<br>Current Freq: 14<br>Percentile: 92nd |

Toggle between modes via button in screen header or in Settings.

---

### 3.3 Picker Screen

**Purpose:** Generate number selections using preliminary (Phase 1) or full baseline (Phase 2) data. Manual and auto modes available in both phases.

*See original wireframe document for full layout. Key update: Picker works during baseline building using preliminary data (Bₚ).*

---

### 3.4 Cycles Screen

**Purpose:** Manage pattern cycles, mark new cycles, and access Baseline Comparison view.

*See original wireframe document for full layout. Key addition: 'Compare Baselines' button links to new Baseline Comparison screen.*

---

### 3.5 History Screen

**Purpose:** Track saved picks, compare against results, view performance statistics.

*See original wireframe document for full layout. Key addition: Export now includes baseline history data.*

---

### 3.6 Settings Screen (Updated)

**Purpose:** Configure app preferences, algorithm parameters, deviation display, and sensitivity settings.

```
┌────────────────────────────────────┐
│            SETTINGS                │
├────────────────────────────────────┤
│                                    │
│  ALGORITHM SETTINGS                │
│  ┌────────────────────────────┐   │
│  │ Smoothing Factor           │   │
│  │ ○ None    ○ Light          │   │
│  │ ● Normal  ○ Heavy          │   │
│  └────────────────────────────┘   │
│  ┌────────────────────────────┐   │
│  │ Shift Detection Sensitivity│   │
│  │ ○ Low (±2.5 std dev)       │   │
│  │ ● Normal (±2.0 std dev)    │   │
│  │ ○ High (±1.5 std dev)      │   │
│  │ ○ Custom: [____]           │   │
│  └────────────────────────────┘   │
│                                    │
│  DISPLAY SETTINGS                  │
│  ┌────────────────────────────┐   │
│  │ Deviation Display          │   │
│  │ ● Simple  ○ Advanced       │   │
│  └────────────────────────────┘   │
│  ┌────────────────────────────┐   │
│  │ Dark Mode          [OFF]   │   │
│  └────────────────────────────┘   │
│                                    │
│  DATA SETTINGS                     │
│  ┌────────────────────────────┐   │
│  │ Include baseline history   │   │
│  │ in CSV export      [ON]    │   │
│  └────────────────────────────┘   │
│  [Refresh Data]  [Clear Cache]    │
│                                    │
├────────────────────────────────────┤
│  🏠    📊    🎯    📅    🕐      │
└────────────────────────────────────┘
```

#### Settings Categories

**Algorithm Settings**
- **Smoothing Factor:** None (raw), Light (0.85/0.15), Normal (0.7/0.3), Heavy (0.5/0.5)
- **Shift Sensitivity:** Low (±2.5), Normal (±2.0), High (±1.5), Custom

**Display Settings**
- **Deviation Display:** Simple (icons/labels) or Advanced (numeric scores)
- **Dark Mode:** Toggle on/off

**Data Settings**
- **Baseline in Export:** Include baseline history in CSV exports
- **Data Actions:** Manual refresh, clear cache

---

### 3.7 Baseline Comparison Screen (NEW)

**Purpose:** Compare Initial Baseline (B₀) against Rolling Baseline (Bₙ) to visualize drift, identify pattern shifts, and make informed cycle decisions.

```
┌────────────────────────────────────┐
│      BASELINE COMPARISON           │
│                    [Simple/Adv]    │
├────────────────────────────────────┤
│                                    │
│  Initial (B₀)      Rolling (Bₙ)   │
│  Draws 1-20        Draws 45-64    │
│                                    │
│  HOT NUMBERS COMPARISON            │
│  ┌──────────────┬──────────────┐  │
│  │ B₀ Hot       │ Bₙ Hot       │  │
│  │ 21 32 45     │ 21 32 12     │  │
│  │ 07 18        │ 07 55        │  │
│  └──────────────┴──────────────┘  │
│                                    │
│  ✓ Shared: 21, 32, 07 (60%)       │
│  ✗ Dropped: 45, 18                │
│  ★ Added: 12, 55                  │
│                                    │
│  OVERLAP SCORE                     │
│  ████████████░░░░░░░░  60%        │
│  ⚠️ Below 50% suggests shift      │
│                                    │
│  DRIFT DETAILS                     │
│  ┌────────────────────────────┐   │
│  │ #  │ B₀  │ Bₙ  │ Chg │Stat│   │
│  │ 45 │  8  │  3  │-62%│ 🧊 │   │
│  │ 18 │  7  │  2  │-71%│ 🧊 │   │
│  │ 12 │  2  │  9  │+350│ 🔥 │   │
│  │ 55 │  3  │  8  │+167│ 🔥 │   │
│  └────────────────────────────┘   │
│  [View Full Report]               │
│                                    │
│  ┌────────────────────────────┐   │
│  │   [Dismiss]  [New Cycle]   │   │
│  └────────────────────────────┘   │
│                                    │
├────────────────────────────────────┤
│           [< Back]                │
└────────────────────────────────────┘
```

#### Baseline Comparison Components

- **Header:** Title, Simple/Advanced toggle
- **Baseline Labels:** Shows which drawing ranges B₀ and Bₙ represent
- **Hot Numbers Comparison:** Side-by-side view of top 5 hot numbers from each baseline
- **Set Analysis:** Shared (in both), Dropped (was in B₀, not in Bₙ), Added (new in Bₙ)
- **Overlap Score:** Visual progress bar showing % of B₀ hot numbers still hot in Bₙ
- **Warning Threshold:** Alert message when overlap drops below 50%
- **Drift Details Table:** Numbers with biggest changes, showing B₀ freq, Bₙ freq, % change, status icon
- **View Full Report:** Expands to show all 69 numbers with drift data
- **Action Buttons:** Dismiss (close view) or Start New Cycle (end current, begin fresh)

#### Advanced Mode Additions

When Advanced mode is selected, the Drift Details table expands to include:
- Deviation score (standard deviations from B₀ mean)
- Percentile rank in both baselines
- Co-occurrence changes (top companions that changed)
- Trend spark line (mini chart of last 20 drawings)

#### Access Points

The Baseline Comparison screen can be accessed from:
- **Dashboard:** 'Compare Baselines' link in baseline status bar (Phase 2 only)
- **Cycles Screen:** 'Compare' button in current cycle card
- **Analysis Screen:** 'B₀ vs Bₙ' tab or button in header
- **Pattern Shift Alert:** Direct link when alert is triggered

---

## 4. Document Status

| # | Document | Status | Notes |
|---|----------|--------|-------|
| 1 | UI Wireframes | v1.1 Complete | Added Baseline Comparison |
| 2 | Project Plan | Complete | v1.0 |
| 3 | Requirements & Design | Updating | Adding baseline algorithm |
| 4 | Folder Structure & Patterns | Next | |
| 5 | Data Flow | Pending | |
| 6 | Data Structure & Schema | Pending | |

---

## 5. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 4, 2025 | Project Owner | Initial wireframes |
| 1.1 | Dec 5, 2025 | Project Owner | Added Baseline Comparison screen, updated Settings with algorithm options, updated Dashboard for phases |
