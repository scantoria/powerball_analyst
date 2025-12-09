import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/local/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage (primary data persistence)
  await HiveService.init();

  // Run the app with Riverpod
  runApp(
    const ProviderScope(
      child: PowerballAnalystApp(),
    ),
  );
}
