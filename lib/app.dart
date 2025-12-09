import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/settings_providers.dart';
import 'ui/navigation/app_navigation.dart';

/// Root application widget
class PowerballAnalystApp extends ConsumerWidget {
  const PowerballAnalystApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);

    return MaterialApp.router(
      routerConfig: AppNavigation.router,
      title: 'Powerball Analyst',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
