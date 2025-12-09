import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

/// Scaffold with bottom navigation bar
/// Automatically syncs with current route
class BottomNavScaffold extends StatelessWidget {
  final Widget child;

  const BottomNavScaffold({
    super.key,
    required this.child,
  });

  static final List<_NavItem> _navItems = [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: '/',
    ),
    _NavItem(
      label: 'Analysis',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      route: '/analysis',
    ),
    _NavItem(
      label: 'Picker',
      icon: Icons.radio_button_unchecked,
      activeIcon: Icons.radio_button_checked,
      route: '/picker',
    ),
    _NavItem(
      label: 'Cycles',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      route: '/cycles',
    ),
    _NavItem(
      label: 'History',
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      route: '/history',
    ),
  ];

  /// Get current index based on location
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _navItems.indexWhere((item) => item.route == location);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          context.go(_navItems[index].route);
        },
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings),
              label: const Text('Settings'),
              backgroundColor: AppColors.primaryBlue,
            )
          : null,
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
