import 'package:flutter/foundation.dart';
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
///
/// Navigation structure:
/// - Bottom Nav Screens (ShellRoute): Dashboard, Analysis, Picker, Cycles, History
/// - Full Screen Routes: Settings, Baseline Comparison
/// - Error handling for 404 pages
class AppNavigation {
  /// Global navigation key for accessing navigator without context
  static final navigatorKey = GlobalKey<NavigatorState>();

  /// Main router configuration
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    observers: [
      _AppNavigationObserver(),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
    routes: [
      // Bottom navigation shell
      ShellRoute(
        builder: (context, state, child) {
          return BottomNavScaffold(child: child);
        },
        routes: [
          // Dashboard (Home)
          GoRoute(
            path: '/',
            name: RouteNames.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          // Analysis Screen
          GoRoute(
            path: '/analysis',
            name: RouteNames.analysis,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalysisScreen(),
            ),
          ),
          // Number Picker Screen
          GoRoute(
            path: '/picker',
            name: RouteNames.picker,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PickerScreen(),
            ),
          ),
          // Cycles Screen
          GoRoute(
            path: '/cycles',
            name: RouteNames.cycles,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CyclesScreen(),
            ),
          ),
          // History Screen
          GoRoute(
            path: '/history',
            name: RouteNames.history,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
        ],
      ),
      // Full screen routes (outside bottom nav)
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/baseline-comparison',
        name: RouteNames.baselineComparison,
        builder: (context, state) => const BaselineComparisonScreen(),
      ),
    ],
  );
}

/// Route names for type-safe navigation
///
/// Usage: context.goNamed(RouteNames.analysis)
class RouteNames {
  static const String dashboard = 'dashboard';
  static const String analysis = 'analysis';
  static const String picker = 'picker';
  static const String cycles = 'cycles';
  static const String history = 'history';
  static const String settings = 'settings';
  static const String baselineComparison = 'baseline-comparison';
}

/// Navigation observer for logging route changes in debug mode
class _AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      debugPrint('Navigation: Pushed ${route.settings.name}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      debugPrint('Navigation: Popped ${route.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (kDebugMode) {
      debugPrint('Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
    }
  }
}

/// Error screen shown when navigation fails or route not found
class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'The requested page could not be found.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
