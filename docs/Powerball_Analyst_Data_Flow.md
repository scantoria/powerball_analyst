# Powerball Analyst
# Data Flow & State Management
**Version 2.0 - December 2025**
**Architecture: Hive-Only (No Firebase)**

---

## 1. Data Flow Overview

This document describes how data moves through the Powerball Analyst application, from external APIs to the user interface, using **Hive as the primary and only data persistence layer**.

### 1.1 High-Level Data Flow (Hive-Only Architecture)

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                             │
│  ┌───────────────────┐                                          │
│  │  NY Open Data API │                                          │
│  │  (Lottery Results)│                                          │
│  └─────────┬─────────┘                                          │
│            │                                                    │
│            ▼                                                    │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    REPOSITORIES                         │  │
│  │   DrawingRepo  │  CycleRepo  │  BaselineRepo  │ PickRepo│  │
│  └─────────────────────────┬───────────────────────────────┘  │
│                            │                                  │
│            ┌───────────────┴───────────────┐                  │
│            ▼                               ▼                  │
│  ┌─────────────────┐           ┌─────────────────────────┐    │
│  │  HIVE STORAGE  │           │    ANALYSIS ENGINE      │    │
│  │ (Primary Store)│           │  Frequency │ Deviation  │    │
│  └────────┬──────┘           │  Baseline  │ Detection  │    │
│           │                   └────────────┬────────────┘    │
│           └───────────────┬───────────────┘                  │
│                           ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              RIVERPOD PROVIDERS (State)                 │  │
│  │   Drawings │ Cycles │ Baselines │ Analysis │ Settings   │  │
│  └─────────────────────────┬───────────────────────────────┘  │
│                            │                                  │
│                            ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │                    UI WIDGETS                           │  │
│  │   Dashboard │ Analysis │ Picker │ Cycles │ History      │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                               │
│  BACKUP: Manual CSV/JSON Export                              │
└─────────────────────────────────────────────────────────────────┘
```

**Key Architecture Decision:**
- **No Firebase** - Removed to simplify architecture
- **Hive is Primary Storage** - All data persisted locally
- **No Cloud Sync** - Single-user personal app
- **Manual Backup** - CSV/JSON export for data backup

---

## 2. API Integration

### 2.1 NY Open Data API

The app fetches Powerball winning numbers from the NY State Open Data API, which provides national Powerball results.

| Property | Value |
|----------|-------|
| Base URL | https://data.ny.gov/resource/d6yy-54nr.json |
| Auth | None required (public API) |
| Rate Limit | 1000 requests/hour without app token |
| Response | JSON array of drawing objects |

**API Response Structure:**
```json
{
  "draw_date": "2025-12-04T00:00:00.000",
  "winning_numbers": "12 25 34 48 67",
  "powerball": "15",
  "multiplier": "2"
}
```

### 2.2 Data Sync Flow (Hive-Only)

- **App Launch:** Check last sync timestamp in Hive metadata
- **Fetch Delta:** Query API for drawings since last sync date
- **Transform:** Convert API response to Drawing model
- **Store:** Write directly to Hive (primary and only storage)
- **Notify:** Invalidate Riverpod providers to trigger UI refresh
- **Analyze:** Trigger baseline recalculation if at 5-drawing interval

### 2.3 Sync Sequence Diagram (Simplified)

```
User          App           Hive         API
 │             │              │            │
 │──Launch────▶│              │            │
 │             │──Get Last───▶│            │
 │             │◀──Timestamp──│            │
 │             │              │            │
 │             │──Fetch Since─────────────▶│
 │             │◀─────────New Drawings─────│
 │             │              │            │
 │             │──Store──────▶│            │
 │             │◀──Confirmed──│            │
 │             │              │            │
 │◀──UI Ready──│              │            │
```

**Note:** No Firebase, no cloud sync. All data is written once to Hive.

---

## 3. Storage Strategy (Hive-Only)

### 3.1 Hive Boxes (Primary Storage)

| Box Name | Data Type | Purpose |
|----------|-----------|---------|
| drawingsBox | Drawing | Lottery results (all historical data) |
| cyclesBox | Cycle | Cycle definitions and metadata |
| baselinesBox | Baseline | Computed baseline snapshots (B₀, Bₙ history) |
| picksBox | Pick | User's saved number selections |
| settingsBox | Map | User preferences (smoothing, sensitivity, display) |
| metadataBox | Map | Sync timestamps, app version, migration flags |

**Total Storage:** ~100KB/year (trivial)

### 3.2 Data Read Flow (Simplified)

Hive is the primary and only storage layer. No caching layer needed.

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA READ FLOW                           │
│                                                             │
│    Request ──▶ Read from Hive ──▶ Return Data              │
│                                                             │
│    (Always available, even offline)                         │
└─────────────────────────────────────────────────────────────┘
```

### 3.3 Provider Invalidation Rules

Riverpod providers invalidate on data changes:

- **Drawings:** Invalidate on successful API sync
- **Baselines:** Invalidate when new drawing added at 5-drawing interval
- **Cycles:** Invalidate on cycle create/close
- **Picks:** Invalidate on save/delete
- **Settings:** Immediate update (no invalidation needed)

---

## 4. Baseline Calculation Flow

### 4.1 Trigger Points

| Trigger | Condition | Action |
|---------|-----------|--------|
| New Drawing | Drawing count % 5 == 0 | Recalculate Bₚ or Bₙ |
| Drawing 20 | Drawing count == 20 | Lock B₀, initialize Bₙ |
| New Cycle | User starts new cycle | Reset all baselines |
| Settings Change | Smoothing factor changed | Recalculate Bₙ with new weight |

### 4.2 Baseline Calculation Pipeline

1. **Get Drawings:** Fetch drawings in target range from repository
2. **Calculate Frequency:** Count occurrences for each number (1-69 white, 1-26 PB)
3. **Build Co-occurrence:** Create pair matrix for companion analysis
4. **Compute Statistics:** Mean, standard deviation, percentiles
5. **Classify Numbers:** Hot (top 20%), cold (bottom 20%), never-drawn
6. **Apply Smoothing:** Blend with previous Bₙ (for rolling baseline)
7. **Store Baseline:** Save to repository, add to history
8. **Check Shifts:** Run pattern shift detection against triggers
9. **Notify Providers:** Invalidate dependent providers

### 4.3 Provider Dependency Graph

```
drawingsProvider
       │
       ▼
currentCycleProvider ─────────────────────────┐
       │                                      │
       ▼                                      │
cycleDrawingsProvider                         │
       │                                      │
       ├────────────────┬────────────────┐    │
       ▼                ▼                ▼    │
frequencyProvider  cooccurrenceProvider  │    │
       │                │                │    │
       └────────┬───────┘                │    │
                ▼                        │    │
       baselineProvider ◀────────────────┘    │
                │                             │
       ┌────────┼────────┬──────────────┐     │
       ▼        ▼        ▼              ▼     │
  hotNumbers  deviation  overlapScore  shiftAlerts
  Provider    Provider   Provider      Provider
```

---

## 5. User Action Flows

### 5.1 Save Pick Flow

1. User selects 5 white balls + 1 Powerball
2. Validation service checks sum range (120-180) and odd/even balance
3. Warning shown if never-drawn numbers selected
4. User confirms save with target drawing date
5. Pick model created with isPreliminary flag (if Phase 1)
6. PickRepository.save() writes to Firebase + Hive
7. picksProvider invalidated, UI updates

### 5.2 Start New Cycle Flow

1. User taps 'Start New Cycle' (from alert or manual)
2. Confirmation dialog shown with impact explanation
3. Current cycle marked as closed with endDate
4. New Cycle created with status='collecting'
5. All baseline references cleared
6. CycleRepository.save() persists both cycles
7. All analysis providers invalidated
8. Dashboard shows 'Building baseline...' state

### 5.3 Auto-Pick Generation Flow

```
User taps 'Auto Pick'
        │
        ▼
PickGenerator.generate()
        │
        ├──▶ Get active baseline (Bₚ or Bₙ)
        ├──▶ Get hot numbers from baseline
        ├──▶ Get co-occurrence matrix
        ├──▶ Get never-drawn list (exclusions)
        │
        ▼
Select first number (weighted random from hot)
        │
        ▼
FOR remaining 4 white balls:
  │  Score = (0.6 × freq_score) + (0.4 × companion_score)
  │  Exclude never-drawn
  └──▶ Select highest scoring candidate
        │
        ▼
Select Powerball (hot PB, exclude never-drawn)
        │
        ▼
ValidationService.validate()
  ├──▶ Check sum range (120-180)
  └──▶ Check odd/even (2-3 or 3-2)
        │
        ▼
Return Pick with explanation
```

---

## 6. Error Handling

### 6.1 Error Types & Recovery

| Error Type | Cause | Recovery |
|------------|-------|----------|
| NetworkException | No internet, API timeout | Use existing Hive data, show offline indicator |
| ApiException | API error response (4xx, 5xx) | Retry with backoff, continue with local data |
| HiveException | Hive read/write error | Clear corrupted box, re-sync from API |
| ValidationException | Invalid pick data | Show validation message to user |

### 6.2 Offline Mode

The app is **offline-first** and works fully without internet:

- **Read Operations:** All analysis, history, and picks work from Hive (always available)
- **Write Operations:** Picks, cycles, and settings work offline (written to Hive immediately)
- **API Sync:** Only needed to fetch new lottery drawings
- **Sync Status:** Last sync timestamp shown in UI
- **Staleness Warning:** Alert if API data older than 7 days

**Key Advantage:** No internet required except for fetching new drawings from API

---

## 7. Document Status

| # | Document | Status | Notes |
|---|----------|--------|-------|
| 1 | UI Wireframes | v1.1 Complete | |
| 2 | Project Plan | v1.0 Complete | |
| 3 | Requirements & Design | v1.1 Complete | |
| 4 | Folder Structure & Patterns | v1.0 Complete | |
| 5 | Data Flow | v1.0 Complete | This document |
| 6 | Data Structure & Schema | Next | |

---

## 8. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 5, 2025 | Project Owner | Initial data flow documentation |
