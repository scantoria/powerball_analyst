# Powerball Analyst
# Requirements & Design v1.1
**December 2025 - Baseline Algorithm Update**

---

## 1. Baseline Algorithm Design

The baseline system establishes a reference point for pattern analysis, enabling meaningful deviation detection and pattern shift identification.

### 1.1 Baseline Types

| Baseline | Definition | Purpose | Mutable? |
|----------|-----------|---------|----------|
| B₀ (Initial) | First 20 drawings of cycle | Historical reference, long-term drift | No (locked) |
| Bₙ (Rolling) | Last 20 drawings, recalc every 5 | Recent trends, short-term shifts | Yes (auto) |
| Bₚ (Preliminary) | Current data in Phase 1 (<20) | Early picks before lock | Yes (temp) |

### 1.2 Phase System

#### PHASE 1: Baseline Collection (Drawings 1-20)

- Collect frequency data from each drawing
- Preliminary baseline (Bₚ) recalculated at drawings 5, 10, 15, 20
- Picks allowed using Bₚ data (marked as 'preliminary')
- At drawing 20: Lock B₀ permanently, store in baseline history

#### PHASE 2: Active Analysis (Drawings 21+)

- Initialize Bₙ = B₀ at transition
- Recalculate Bₙ every 5 drawings (25, 30, 35...)
- Apply configurable smoothing factor to Bₙ
- Compare current data against both B₀ and Bₙ
- Detect pattern shifts using configurable sensitivity

### 1.3 Smoothing Factor

Smoothing prevents over-reaction to short-term noise when recalculating Bₙ:

```
New Bₙ = (weight × Previous Bₙ) + ((1-weight) × Latest 5 Drawings)
```

**Configurable Options:**
- **None:** Raw recalculation (no smoothing)
- **Light:** 0.85 previous + 0.15 new
- **Normal (default):** 0.70 previous + 0.30 new
- **Heavy:** 0.50 previous + 0.50 new

### 1.4 Deviation Scoring

Deviation measures how far current performance differs from baseline:

```
Deviation = (Current Freq - Baseline Freq) / Baseline Std Dev
```

#### Simple Mode Display:

| Label | Condition | Icon | Color |
|-------|-----------|------|-------|
| Hot Rising | > +1.5 | ↑↑ | Red |
| Warming | +0.5 to +1.5 | ↑ | Orange |
| Stable | -0.5 to +0.5 | ● | Green |
| Cooling | -1.5 to -0.5 | ↓ | Light Blue |
| Cold Falling | < -1.5 | ↓↓ | Blue |

#### Advanced Mode Display:

- Numeric deviation score (e.g., +1.82)
- B₀ frequency, Bₙ frequency, Current frequency
- Percentile rank
- Trend spark line

### 1.5 Pattern Shift Detection

Pattern shifts are detected by comparing B₀ against Bₙ and current data:

| Trigger | Condition | Compares |
|---------|-----------|----------|
| Long-term Drift | 5+ B₀ hot numbers now below average | B₀ |
| Short-term Surge | 3+ numbers jump > +2.0 dev in 5 drawings | Bₙ |
| Baseline Divergence | B₀ and Bₙ hot sets differ > 50% | Both |
| Correlation Breakdown | Top 5 B₀ pairs no longer co-occurring | B₀ |
| New Dominance | Number not in B₀ top 30% is now #1 or #2 | B₀ |

**Sensitivity Settings:**
- **Low:** ±2.5 std dev (fewer alerts)
- **Normal:** ±2.0 std dev (default)
- **High:** ±1.5 std dev (more alerts)
- **Custom:** User-defined threshold

---

## 2. New Baseline Requirements

The following requirements have been added to support the baseline algorithm system:

| ID | Requirement | Priority | Category |
|----|-------------|----------|----------|
| AN-12 | System shall establish initial baseline (B₀) after 20 drawings | P1 | Baseline |
| AN-13 | System shall lock and preserve initial baseline permanently | P1 | Baseline |
| AN-14 | System shall recalculate rolling baseline (Bₙ) every 5 drawings | P1 | Baseline |
| AN-15 | System shall store baseline history for trend analysis | P2 | Baseline |
| AN-16 | System shall allow picks using preliminary data during Phase 1 | P1 | Baseline |
| AN-17 | System shall compare deviations against both B₀ and Bₙ | P1 | Baseline |
| AN-18 | System shall provide simple and advanced deviation display modes | P2 | Display |
| AN-19 | System shall allow sensitivity adjustment for shift detection | P2 | Settings |
| AN-20 | System shall apply configurable smoothing to Bₙ recalculation | P2 | Algorithm |
| AN-21 | System shall provide baseline comparison view (B₀ vs Bₙ) | P2 | UI |
| AN-22 | System shall calculate and display overlap score between baselines | P2 | Analysis |
| AN-23 | System shall highlight numbers that dropped or rose between baselines | P2 | Analysis |
| AN-24 | System shall include baseline history in CSV exports | P3 | Export |
| AN-25 | System shall allow smoothing factor adjustment in settings | P3 | Settings |

---

## 3. Baseline Comparison Acceptance Criteria

- Displays B₀ and Bₙ drawing ranges clearly
- Shows side-by-side hot number comparison
- Calculates and displays overlap score as percentage
- Shows warning when overlap drops below 50%
- Lists shared, dropped, and added hot numbers
- Displays drift details table with change percentages
- Supports Simple/Advanced display toggle
- Provides 'View Full Report' expansion
- Includes 'Dismiss' and 'Start New Cycle' actions
- Accessible from Dashboard, Cycles, Analysis, and shift alerts

---

## 4. Document Status

| # | Document | Status | Notes |
|---|----------|--------|-------|
| 1 | UI Wireframes | v1.1 Complete | Baseline Comparison added |
| 2 | Project Plan | v1.0 Complete | |
| 3 | Requirements & Design | v1.1 Complete | Baseline algorithm added |
| 4 | Folder Structure & Patterns | Next | |
| 5 | Data Flow | Pending | |
| 6 | Data Structure & Schema | Pending | |

---

## 5. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 4, 2025 | Project Owner | Initial requirements |
| 1.1 | Dec 5, 2025 | Project Owner | Added baseline algorithm, 14 new requirements, comparison criteria |
