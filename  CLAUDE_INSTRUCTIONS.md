I'm working on the Powerball Analyst Flutter project. We've made an architectural decision to REMOVE Firebase from the project and use Hive-only for all data persistence.

KEY CHANGES:

1. REMOVE all Firebase dependencies:
    - Remove firebase_core from pubspec.yaml
    - Remove cloud_firestore from pubspec.yaml
    - Do NOT create any Firebase configuration files
    - Do NOT create firebase_options.dart

2. DATA ARCHITECTURE is now:
   NY Open Data API → Hive (local storage) → UI

   NOT:
   NY Open Data API → Firebase → Hive → UI

3. REPOSITORIES should:
    - Read/write ONLY to Hive
    - No Firestore references
    - No dual-write logic
    - No sync status tracking for cloud

4. UPDATED pubspec.yaml dependencies:
    - flutter_riverpod: ^2.4.0
    - hive_flutter: ^1.1.0
    - dio: ^5.4.0
    - go_router: ^12.0.0
    - fl_chart: ^0.65.0
    - intl: ^0.18.0
    - uuid: ^4.2.0
    - freezed_annotation: ^2.4.0
    - json_annotation: ^4.8.0

5. BACKUP STRATEGY:
    - Export to CSV/JSON for manual backup
    - No cloud sync required

6. RATIONALE:
    - Personal single-user beta app
    - ~100 KB/year storage (trivial)
    - Reduces complexity
    - Eliminates internet dependency for writes
    - Saves ~8-10 hours of development

The project documentation in /docs references Firebase in some places - those references are now outdated. Use Hive-only approach for all data persistence.