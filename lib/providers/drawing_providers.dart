import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drawing.dart';
import '../services/sync/data_sync_service.dart';
import 'repository_providers.dart';

/// Provider for all drawings
final drawingsProvider = Provider<List<Drawing>>((ref) {
  final repo = ref.watch(drawingRepositoryProvider);
  // Return all drawings, sorted by date descending
  return repo.getAll();
});

/// Provider for latest drawing
final latestDrawingProvider = Provider<Drawing?>((ref) {
  final repo = ref.watch(drawingRepositoryProvider);
  return repo.getLatestDrawing();
});

/// Provider for drawing count
final drawingCountProvider = Provider<int>((ref) {
  final repo = ref.watch(drawingRepositoryProvider);
  return repo.getCount();
});

/// Provider for sync status
final syncStatusProvider = FutureProvider<SyncStatus>((ref) async {
  final syncService = ref.watch(dataSyncServiceProvider);
  return await syncService.getSyncStatus();
});

/// Provider for sync operation
/// Call this to trigger a sync
final syncDrawingsProvider = FutureProvider.family<SyncResult, bool>(
  (ref, forceRefresh) async {
    final syncService = ref.watch(dataSyncServiceProvider);
    if (forceRefresh) {
      return await syncService.fullRefresh();
    }
    return await syncService.syncDrawings();
  },
);
