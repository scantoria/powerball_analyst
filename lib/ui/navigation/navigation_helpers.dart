import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_navigation.dart';

/// Navigation helper utilities for common navigation patterns
class NavigationHelpers {
  /// Navigate to dashboard (home)
  static void goToDashboard(BuildContext context) {
    context.goNamed(RouteNames.dashboard);
  }

  /// Navigate to analysis screen
  static void goToAnalysis(BuildContext context) {
    context.goNamed(RouteNames.analysis);
  }

  /// Navigate to picker screen
  static void goToPicker(BuildContext context) {
    context.goNamed(RouteNames.picker);
  }

  /// Navigate to cycles screen
  static void goToCycles(BuildContext context) {
    context.goNamed(RouteNames.cycles);
  }

  /// Navigate to history screen
  static void goToHistory(BuildContext context) {
    context.goNamed(RouteNames.history);
  }

  /// Navigate to settings screen (push, not replace)
  static void goToSettings(BuildContext context) {
    context.pushNamed(RouteNames.settings);
  }

  /// Navigate to baseline comparison screen
  static void goToBaselineComparison(BuildContext context) {
    context.pushNamed(RouteNames.baselineComparison);
  }

  /// Pop current route if possible, otherwise go to dashboard
  static void goBackOrDashboard(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.dashboard);
    }
  }

  /// Show confirmation dialog before navigating back
  static Future<bool> showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit'),
        content: const Text('Are you sure you want to go back? Any unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Navigate with unsaved changes confirmation
  static Future<void> goWithConfirmation(
    BuildContext context,
    VoidCallback navigation, {
    bool hasUnsavedChanges = false,
  }) async {
    if (hasUnsavedChanges) {
      final confirmed = await showExitConfirmation(context);
      if (confirmed) {
        navigation();
      }
    } else {
      navigation();
    }
  }

  /// Get current route location
  static String getCurrentLocation(BuildContext context) {
    return GoRouterState.of(context).uri.toString();
  }

  /// Check if currently on a specific route
  static bool isOnRoute(BuildContext context, String routeName) {
    final currentLocation = getCurrentLocation(context);
    final routes = {
      RouteNames.dashboard: '/',
      RouteNames.analysis: '/analysis',
      RouteNames.picker: '/picker',
      RouteNames.cycles: '/cycles',
      RouteNames.history: '/history',
      RouteNames.settings: '/settings',
      RouteNames.baselineComparison: '/baseline-comparison',
    };
    return currentLocation == routes[routeName];
  }
}
