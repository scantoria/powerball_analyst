/// Validates user picks and auto-picks against Powerball rules
class ValidationService {
  /// Validate a complete pick
  /// Returns ValidationResult with errors and warnings
  ValidationResult validatePick(List<int> whiteBalls, int powerball) {
    final errors = <String>[];
    final warnings = <String>[];

    // White balls validation
    if (whiteBalls.length != 5) {
      errors.add('Must select exactly 5 white balls (got ${whiteBalls.length})');
    }

    if (whiteBalls.toSet().length != whiteBalls.length) {
      errors.add('White balls must be unique (no duplicates)');
    }

    for (final ball in whiteBalls) {
      if (ball < 1 || ball > 69) {
        errors.add('White ball $ball is out of range (must be 1-69)');
      }
    }

    // Powerball validation
    if (powerball < 1 || powerball > 26) {
      errors.add('Powerball must be between 1-26 (got $powerball)');
    }

    // Warnings (not errors - pick is still valid)
    if (errors.isEmpty) {
      final sumTotal = whiteBalls.reduce((a, b) => a + b);
      if (sumTotal < 120 || sumTotal > 180) {
        warnings.add(
            'Sum total $sumTotal is outside optimal range (120-180)');
      }

      final oddCount = whiteBalls.where((n) => n.isOdd).length;
      if (oddCount < 2 || oddCount > 3) {
        warnings.add(
            'Odd count $oddCount is outside optimal range (2-3)');
      }

      // Check for consecutive numbers (may be a warning)
      final sorted = List<int>.from(whiteBalls)..sort();
      int consecutiveCount = 0;
      for (int i = 0; i < sorted.length - 1; i++) {
        if (sorted[i + 1] == sorted[i] + 1) {
          consecutiveCount++;
        }
      }
      if (consecutiveCount >= 3) {
        warnings.add(
            'Pick contains $consecutiveCount consecutive numbers (unusual pattern)');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Quick validation check (returns bool)
  bool isValidPick(List<int> whiteBalls, int powerball) {
    return validatePick(whiteBalls, powerball).isValid;
  }

  /// Validate just white balls
  bool areValidWhiteBalls(List<int> whiteBalls) {
    if (whiteBalls.length != 5) return false;
    if (whiteBalls.toSet().length != 5) return false;
    return whiteBalls.every((ball) => ball >= 1 && ball <= 69);
  }

  /// Validate just powerball
  bool isValidPowerball(int powerball) {
    return powerball >= 1 && powerball <= 26;
  }
}

/// Result of pick validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  String get message {
    if (isValid && warnings.isEmpty) return 'Valid pick';
    if (isValid && warnings.isNotEmpty) {
      return 'Valid with warnings: ${warnings.join(', ')}';
    }
    return 'Invalid: ${errors.join(', ')}';
  }

  /// Get all issues (errors + warnings) as a single list
  List<String> get allIssues => [...errors, ...warnings];
}
