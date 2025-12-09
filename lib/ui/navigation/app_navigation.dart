import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/analysis/analysis_screen.dart';
import '../screens/picker/picker_screen.dart';
import '../screens/cycles/cycles_screen.dart';
import '../screens/cycles/baseline_comparison_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'bottom_nav_scaffold.dart';

/// App navigation configuration using go_router
class AppNavigation {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return BottomNavScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/analysis',
            name: 'analysis',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalysisScreen(),
            ),
          ),
          GoRoute(
            path: '/picker',
            name: 'picker',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PickerScreen(),
            ),
          ),
          GoRoute(
            path: '/cycles',
            name: 'cycles',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CyclesScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
        ],
      ),
      // Routes outside bottom nav
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/baseline-comparison',
        name: 'baseline-comparison',
        builder: (context, state) => const BaselineComparisonScreen(),
      ),
    ],
  );
}
