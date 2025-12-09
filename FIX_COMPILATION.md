# Compilation Fix Guide

## Issue
The app won't compile because Freezed generated files are missing. All 7 models use Freezed for immutable data classes and require code generation.

## Quick Fix

Run this command in the project root:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate all the missing `.freezed.dart` and `.g.dart` files.

## What This Does

The `build_runner` will generate 14 files:
- `lib/models/drawing.freezed.dart` + `drawing.g.dart`
- `lib/models/cycle.freezed.dart` + `cycle.g.dart`
- `lib/models/baseline.freezed.dart` + `baseline.g.dart`
- `lib/models/pick.freezed.dart` + `pick.g.dart`
- `lib/models/pattern_shift.freezed.dart` + `pattern_shift.g.dart`
- `lib/models/settings.freezed.dart` + `settings.g.dart`
- `lib/models/number_stats.freezed.dart` + `number_stats.g.dart`

## After Generation

Once the files are generated, you can:

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Watch for changes (during development):**
   ```bash
   flutter pub run build_runner watch
   ```
   This will automatically regenerate files when you modify models.

## Verifying Success

After running build_runner, check that the generated files exist:
```bash
ls -la lib/models/*.freezed.dart
ls -la lib/models/*.g.dart
```

You should see 14 generated files (7 x 2).

## Common Issues

### "Conflicting outputs"
If you see this error, use the `--delete-conflicting-outputs` flag:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Generated files in .gitignore
The generated files are intentionally excluded from git (they're in `.gitignore`). This is correct - they should be regenerated locally.

## Next Steps

After fixing compilation:
1. Run `flutter pub get` to ensure all dependencies are installed
2. Run `flutter run` to launch the app
3. Verify navigation works between all 5 screens
4. Test dark mode toggle in Settings
