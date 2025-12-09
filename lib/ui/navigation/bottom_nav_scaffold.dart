import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

/// Scaffold with bottom navigation bar
class BottomNavScaffold extends StatefulWidget {
  final Widget child;

  const BottomNavScaffold({
    super.key,
    required this.child,
  });

  @override
  State<BottomNavScaffold> createState() => _BottomNavScaffoldState();
}

class _BottomNavScaffoldState extends State<BottomNavScaffold> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
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
      floatingActionButton: _currentIndex == 0
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
