import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/drawing_repository.dart';
import '../data/repositories/cycle_repository.dart';
import '../data/repositories/baseline_repository.dart';
import '../data/repositories/pick_repository.dart';
import '../data/repositories/pattern_shift_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/api/ny_lottery_api.dart';
import '../services/sync/data_sync_service.dart';
import '../services/orchestration/cycle_orchestration_service.dart';
import 'analysis_providers.dart';

/// Providers for repositories and services
///
/// These are singleton instances that can be accessed throughout the app

// API Client
final nyLotteryApiProvider = Provider<NYLotteryApi>((ref) {
  return NYLotteryApi();
});

// Repositories
final drawingRepositoryProvider = Provider<DrawingRepository>((ref) {
  return DrawingRepository();
});

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  return CycleRepository();
});

final baselineRepositoryProvider = Provider<BaselineRepository>((ref) {
  return BaselineRepository();
});

final pickRepositoryProvider = Provider<PickRepository>((ref) {
  return PickRepository();
});

final patternShiftRepositoryProvider = Provider<PatternShiftRepository>((ref) {
  return PatternShiftRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// Services
final dataSyncServiceProvider = Provider<DataSyncService>((ref) {
  return DataSyncService(
    api: ref.watch(nyLotteryApiProvider),
    drawingRepo: ref.watch(drawingRepositoryProvider),
  );
});

// Orchestration Services
final cycleOrchestrationServiceProvider = Provider<CycleOrchestrationService>((ref) {
  return CycleOrchestrationService(
    drawingRepo: ref.watch(drawingRepositoryProvider),
    cycleRepo: ref.watch(cycleRepositoryProvider),
    baselineRepo: ref.watch(baselineRepositoryProvider),
    shiftRepo: ref.watch(patternShiftRepositoryProvider),
    baselineCalc: ref.watch(baselineCalculatorProvider),
    shiftDetector: ref.watch(patternShiftDetectorProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
  );
});
