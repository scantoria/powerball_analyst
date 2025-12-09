# Powerball Analyst - Architecture Overview
**Version 2.0 - Hive-Only Architecture**
**Updated: December 8, 2025**

---

## 🎯 Key Architectural Decision: Hive-Only Storage

We have **removed Firebase** from the project and adopted a **Hive-only architecture**.

### Rationale

1. **Personal Single-User App** - No need for cloud sync
2. **Trivial Storage** - ~100KB/year data footprint
3. **Reduced Complexity** - Eliminates dual-write logic, sync status tracking
4. **Offline-First** - App works fully without internet (except for API fetches)
5. **Development Time** - Saves 8-10 hours of Firebase setup and integration
6. **Cost** - No Firebase costs or quotas to manage

---

## 📊 Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                   NY Open Data API                      │
│              (Powerball Lottery Results)                │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
       ┌──────────────────────┐
       │   DrawingRepository  │
       └──────────┬───────────┘
                  │
                  ▼
         ┌────────────────┐
         │  HIVE STORAGE  │ ◄─── Primary & Only Persistence
         │  (Local Only)  │
         └────────┬───────┘
                  │
                  ▼
       ┌──────────────────────┐
       │ Riverpod Providers   │
       │    (State Layer)     │
       └──────────┬───────────┘
                  │
                  ▼
            ┌─────────┐
            │   UI    │
            └─────────┘
```

**Simplified:** `API → Hive → UI`

---

## 🗄️ Storage Structure

### Hive Boxes (7 total)

| Box Name | Purpose | Estimated Size |
|----------|---------|----------------|
| `drawingsBox` | All lottery results | ~50KB/year |
| `cyclesBox` | Pattern cycles | ~5KB total |
| `baselinesBox` | Statistical snapshots (B₀, Bₙ, history) | ~30KB/year |
| `picksBox` | User number selections | ~10KB/year |
| `shiftsBox` | Pattern shift alerts | ~5KB/year |
| `settingsBox` | User preferences | <1KB |
| `metadataBox` | Sync timestamps, app metadata | <1KB |

**Total Storage: ~100KB/year** (trivial for local storage)

---

## 🔄 Data Lifecycle

### 1. Fetching New Drawings (API → Hive)

```
App Launch
    ↓
Check lastSyncAt (from metadataBox)
    ↓
Fetch new drawings from API (since lastSyncAt)
    ↓
Transform API response to Drawing model
    ↓
Write directly to Hive (drawingsBox)
    ↓
Update lastSyncAt in metadataBox
    ↓
Invalidate Riverpod providers
    ↓
UI updates
```

### 2. User Creates Pick (UI → Hive)

```
User selects numbers
    ↓
Validate (sum range, odd/even, never-drawn warning)
    ↓
Create Pick model
    ↓
Write directly to Hive (picksBox)
    ↓
Invalidate picksProvider
    ↓
UI updates
```

### 3. Baseline Calculation (Triggered every 5 drawings)

```
New drawing added (count % 5 == 0)
    ↓
Read drawings from Hive (last 20)
    ↓
Calculate frequencies, co-occurrence, statistics
    ↓
Apply smoothing (if Bₙ rolling baseline)
    ↓
Write Baseline to Hive (baselinesBox)
    ↓
Run pattern shift detection
    ↓
Write PatternShift alerts (if any) to Hive (shiftsBox)
    ↓
Invalidate baselineProvider & shiftProvider
    ↓
UI updates
```

---

## 💾 Backup Strategy

**No Cloud Sync** - Manual backup via export:

1. **CSV Export** - Drawings, cycles, picks, baselines
2. **JSON Export** - Full data dump for restore
3. **Export Trigger** - Settings screen or automatic periodic prompt
4. **Import** - JSON restore (future feature)

User is responsible for backing up data manually.

---

## 🚫 What Was Removed

### Dependencies Removed
- `firebase_core: ^2.24.0`
- `cloud_firestore: ^4.13.0`
- `fake_cloud_firestore: ^2.4.0` (dev)

### Files Deleted
- `lib/firebase/firebase_options.dart`
- `lib/firebase/` directory

### Code Updated
- `lib/main.dart` - Removed Firebase initialization
- `lib/data/local/hive_service.dart` - Enhanced with export/stats methods
- `docs/Powerball_Analyst_Data_Flow.md` - v2.0 (Hive-only)
- `docs/Powerball_Analyst_Data_Schema.md` - v2.0 (Hive-only)
- `SETUP.md` - Updated for Hive-only architecture

---

## 🏗️ Repository Pattern (Hive-Only)

All repositories read/write **only to Hive**. No dual-write logic.

```dart
// Example: DrawingRepository
class DrawingRepository {
  final Box<Drawing> _box = HiveService.getBox(HiveService.drawingsBox);

  // Write directly to Hive
  Future<void> save(Drawing drawing) async {
    await _box.put(drawing.id, drawing);
  }

  // Read directly from Hive
  Drawing? getById(String id) {
    return _box.get(id);
  }

  // Query in-memory (Hive doesn't have indexing)
  List<Drawing> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.drawDate.compareTo(a.drawDate));
  }
}
```

**Key Points:**
- No Firebase references
- No sync status tracking
- No network error handling for writes (only reads from API)
- Simple, direct Hive access

---

## 🧪 Testing Strategy

### Unit Tests
- Test repositories with real Hive boxes (in-memory)
- Test analysis algorithms with mock data
- Test model serialization (Freezed/JSON)

### Widget Tests
- Test UI components with mock providers
- No need for `fake_cloud_firestore`

### Integration Tests
- Test full data flow: API → Hive → UI
- Test offline capabilities
- Test export/import functionality

---

## 📈 Performance Characteristics

### Hive Performance
- **Read:** O(1) direct key lookup, O(n) for queries
- **Write:** O(1) single write
- **Storage:** Lazy-loaded boxes, minimal memory footprint
- **Watch Streams:** Reactive updates on box changes

### Expected App Performance
- **Cold Start:** <2 seconds (Hive init + box open)
- **Warm Start:** <500ms
- **Data Fetch:** ~200-500ms (NY Open Data API)
- **Baseline Calc:** <100ms (20 drawings, simple stats)
- **Pick Generation:** <50ms (weighted random + validation)

---

## 🔮 Future Considerations

### If Cloud Sync is Ever Needed
1. Add Firebase dependencies back
2. Implement sync service with conflict resolution
3. Use Hive as cache layer (same as before)
4. Estimated effort: ~10 hours

### Alternative Cloud Options
- Supabase (PostgreSQL)
- Appwrite (self-hosted)
- Custom REST API + server

For now: **Not needed**. Hive-only is sufficient for personal use.

---

## ✅ Benefits of This Architecture

1. **Simplicity** - Single source of truth (Hive)
2. **Offline-First** - Works without internet
3. **Fast** - No network latency for writes
4. **Private** - No data leaves device
5. **Cost-Free** - No Firebase costs
6. **Maintainable** - Less code, fewer dependencies

---

## 📝 Documentation Status

All documentation has been updated to reflect Hive-only architecture:

- ✅ `docs/Powerball_Analyst_Data_Flow.md` - v2.0
- ✅ `docs/Powerball_Analyst_Data_Schema.md` - v2.0
- ✅ `SETUP.md` - Updated
- ✅ `lib/data/local/hive_service.dart` - Enhanced
- ✅ `lib/main.dart` - Firebase removed
- ✅ `pubspec.yaml` - Firebase dependencies removed

---

## 🚀 Ready for Development

The foundation is solid and Firebase-free. Ready to implement:

- **Phase 2:** Repositories, API client, screens
- **Phase 3:** Analysis engine, algorithms
- **Phase 4:** Testing, polish, deployment

Total effort saved: **~10 hours** by removing Firebase.
