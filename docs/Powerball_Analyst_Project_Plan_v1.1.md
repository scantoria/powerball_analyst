# Powerball Analyst
# Project Plan v1.1
**December 2025 - Revised with Baseline Algorithm Updates**

---

## 1. Executive Summary

Personal beta mobile app for analyzing Powerball lottery patterns based on 10+ years of manual tracking data. This revision (v1.1) incorporates the expanded baseline algorithm system with three-baseline tracking, smoothing factors, and enhanced pattern detection.

### 1.1 Project Overview

| Property | Value |
|----------|-------|
| Project Name | Powerball Analyst |
| Platform | Mobile (iOS/Android) via Flutter |
| Duration | 10-12 weeks |
| Estimated Effort | 163 hours (revised from 143) |
| Tech Stack | Flutter, Firebase Firestore, Riverpod, Hive, NY Open Data API |

### 1.2 v1.1 Changes Summary

- **Three-baseline system:** B₀ (initial), Bₙ (rolling), Bₚ (preliminary)
- **Phase system:** Phase 1 (collecting) and Phase 2 (active analysis)
- **Smoothing factor:** Configurable baseline smoothing (none/light/normal/heavy)
- **New UI screen:** Baseline Comparison (B₀ vs Bₙ)
- **Enhanced detection:** 5 pattern shift triggers with dual-baseline comparison
- **14 new requirements:** AN-12 through AN-25
- **Effort increase:** +20 hours (143 → 163)

---

## 2. Project Timeline

| Phase | Focus | Duration | Hours | Key Deliverables |
|-------|-------|----------|-------|------------------|
| Phase 1 | Foundation | 2 weeks | 28 | Project setup, models, Firebase |
| Phase 2 | Core Features | 3-4 weeks | 52 | All screens, baseline system, picks |
| Phase 3 | Analysis Engine | 3 weeks | 48 | Algorithms, detection, auto-pick |
| Phase 4 | Polish & Deploy | 2 weeks | 35 | Testing, optimization, release |
| **TOTAL** | | **10-12 wks** | **163** | |

---

## 3. Detailed Task Breakdown

### PHASE 1: Foundation (28 hours)

| ID | Task | Hours | Status |
|----|------|-------|--------|
| 1.1 | Flutter project setup, folder structure | 3 | Not Started |
| 1.2 | Configure dependencies (pubspec.yaml) | 2 | Not Started |
| 1.3 | Firebase project setup and configuration | 3 | Not Started |
| 1.4 | Hive local storage initialization | 2 | Not Started |
| 1.5 | Create Drawing model with Freezed | 2 | Not Started |
| 1.6 | Create Cycle model with status enum | 2 | Not Started |
| 1.7 | Create Baseline model (B₀, Bₙ, Bₚ support) | 3 | Not Started |
| 1.8 | Create Pick model | 2 | Not Started |
| 1.9 | Create PatternShift model with triggers | 2 | Not Started |
| 1.10 | Create Settings model with smoothing/sensitivity | 2 | Not Started |
| 1.11 | Create NumberStats model | 1 | Not Started |
| 1.12 | Set up Riverpod providers structure | 2 | Not Started |
| 1.13 | Configure go_router navigation | 2 | Not Started |

### PHASE 2: Core Features (52 hours)

| ID | Task | Hours | Status |
|----|------|-------|--------|
| 2.1 | NY Open Data API client (Dio) | 4 | Not Started |
| 2.2 | DrawingRepository (Firebase + Hive) | 4 | Not Started |
| 2.3 | CycleRepository with status management | 4 | Not Started |
| 2.4 | BaselineRepository with history tracking | 4 | Not Started |
| 2.5 | PickRepository with match evaluation | 3 | Not Started |
| 2.6 | Data sync service (API → Firebase → Hive) | 4 | Not Started |
| 2.7 | Dashboard screen with phase status display | 5 | Not Started |
| 2.8 | Analysis screen with heat map | 5 | Not Started |
| 2.9 | Number Picker screen with validation | 5 | Not Started |
| 2.10 | Cycles screen with timeline | 4 | Not Started |
| 2.11 | Baseline Comparison screen (NEW) | 5 | Not Started |
| 2.12 | History screen with filtering | 3 | Not Started |
| 2.13 | Settings screen with algorithm options | 3 | Not Started |
| 2.14 | Shared widgets (NumberBall, HeatMapGrid, etc.) | 4 | Not Started |

### PHASE 3: Analysis Engine (48 hours)

| ID | Task | Hours | Status |
|----|------|-------|--------|
| 3.1 | FrequencyAnalyzer service | 4 | Not Started |
| 3.2 | CooccurrenceAnalyzer service | 5 | Not Started |
| 3.3 | BaselineCalculator with phase logic | 6 | Not Started |
| 3.4 | Smoothing factor implementation | 4 | Not Started |
| 3.5 | DeviationCalculator service | 4 | Not Started |
| 3.6 | PatternShiftDetector (5 triggers) | 8 | Not Started |
| 3.7 | Overlap score calculation (B₀ vs Bₙ) | 3 | Not Started |
| 3.8 | PickGenerator (auto-pick algorithm) | 6 | Not Started |
| 3.9 | ValidationService (sum, odd/even, never-drawn) | 3 | Not Started |
| 3.10 | Analysis providers integration | 5 | Not Started |

### PHASE 4: Polish & Deploy (35 hours)

| ID | Task | Hours | Status |
|----|------|-------|--------|
| 4.1 | Unit tests for models | 4 | Not Started |
| 4.2 | Unit tests for analysis services | 6 | Not Started |
| 4.3 | Widget tests for screens | 5 | Not Started |
| 4.4 | Integration testing | 4 | Not Started |
| 4.5 | Performance optimization | 4 | Not Started |
| 4.6 | Error handling and edge cases | 4 | Not Started |
| 4.7 | App icon and splash screen | 2 | Not Started |
| 4.8 | Build configuration (Android/iOS) | 3 | Not Started |
| 4.9 | Beta deployment and testing | 3 | Not Started |

---

## 4. Effort Comparison (v1.0 → v1.1)

| Phase | v1.0 | v1.1 | Delta | Reason |
|-------|------|------|-------|--------|
| Phase 1: Foundation | 24 | 28 | +4 | Enhanced models |
| Phase 2: Core Features | 44 | 52 | +8 | New screen + repos |
| Phase 3: Analysis Engine | 42 | 48 | +6 | Smoothing + detection |
| Phase 4: Polish & Deploy | 33 | 35 | +2 | More test coverage |
| **TOTAL** | **143** | **163** | **+20** | |

**Key additions driving effort increase:**
- Baseline Comparison screen (+5 hours)
- Three-baseline model complexity (+3 hours)
- Smoothing factor implementation (+4 hours)
- Enhanced pattern shift detection (+4 hours)
- Overlap score and comparison logic (+3 hours)
- Additional test coverage (+2 hours)

---

## 5. Risks & Mitigations

| Risk | Level | Mitigation |
|------|-------|-----------|
| API changes or downtime | Medium | Cache-first architecture, offline mode |
| Baseline algorithm complexity | Medium | Comprehensive unit tests, phased rollout |
| Pattern detection false positives | Medium | Adjustable sensitivity, dismiss option |
| Firebase costs at scale | Low | Personal use only, Hive reduces reads |
| Scope creep | High | Prioritized requirements (P1/P2/P3), MVP first |

---

## 6. Document Status

| # | Document | Status | Notes |
|---|----------|--------|-------|
| 1 | UI Wireframes | v1.1 Complete | |
| 2 | Project Plan | v1.1 Complete | This document |
| 3 | Requirements & Design | v1.1 Complete | |
| 4 | Folder Structure & Patterns | v1.0 Complete | |
| 5 | Data Flow | v1.0 Complete | |
| 6 | Data Structure & Schema | v1.0 Complete | |

---

## 7. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 4, 2025 | Project Owner | Initial project plan |
| 1.1 | Dec 8, 2025 | Project Owner | Added baseline algorithm tasks, +20 hours, new screen |
