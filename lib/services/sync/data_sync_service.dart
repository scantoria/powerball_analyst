import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/api/ny_lottery_api.dart';
import '../../data/repositories/drawing_repository.dart';
import '../../data/local/hive_service.dart';
import '../../models/drawing.dart';

/// Service for synchronizing data from NY Open Data API to Hive storage
///
/// Data Flow: NY Open Data API → Hive (local storage)
///
/// No Firebase, no cloud sync. This service handles:
/// - Fetching new lottery drawings from the API
/// - Transforming API data to Drawing models
/// - Storing in Hive (primary and only persistence)
/// - Tracking sync status in metadataBox
///
/// Sync Strategies:
/// 1. Incremental: Fetch only new drawings since last sync
/// 2. Full Refresh: Fetch latest 100 drawings
/// 3. Historical: Fetch all drawings from API start date (2010)
///
/// Error Handling:
/// - Automatic retry on transient failures
/// - Individual drawing errors don't fail entire sync
/// - Validation of API data before storage
class DataSyncService {
  final NYLotteryApi _api;
  final DrawingRepository _drawingRepo;
  final _uuid = const Uuid();

  /// Dataset start date (Powerball data available from 2010)
  static final DateTime apiStartDate = DateTime(2010, 1, 1);

  DataSyncService({
    NYLotteryApi? api,
    DrawingRepository? drawingRepo,
  })  : _api = api ?? NYLotteryApi(),
        _drawingRepo = drawingRepo ?? DrawingRepository();

  /// Sync new drawings from the API (incremental sync)
  /// Returns the number of new/updated drawings
  Future<SyncResult> syncDrawings() async {
    try {
      if (kDebugMode) {
        debugPrint('[DataSyncService] Starting incremental sync...');
      }

      final lastSyncDate = await _getLastSyncDate();
      final apiData = lastSyncDate != null
          ? await _api.fetchDrawingsSince(lastSyncDate)
          : await _api.fetchLatestDrawings(100); // First sync: get latest 100

      if (apiData.isEmpty) {
        if (kDebugMode) {
          debugPrint('[DataSyncService] No new drawings to sync');
        }
        return SyncResult(
          success: true,
          newDrawingsCount: 0,
          message: 'No new drawings to sync',
        );
      }

      // Transform and validate API data
      final drawings = <Drawing>[];
      int skipped = 0;

      for (final data in apiData) {
        try {
          final drawing = _transformApiDataToDrawing(data);
          if (_validateDrawing(drawing)) {
            drawings.add(drawing);
          } else {
            skipped++;
            if (kDebugMode) {
              debugPrint('[DataSyncService] Invalid drawing skipped: ${drawing.id}');
            }
          }
        } catch (e) {
          skipped++;
          if (kDebugMode) {
            debugPrint('[DataSyncService] Error transforming drawing: $e');
          }
        }
      }

      // Use upsert for efficient save (only updates if changed)
      int updated = 0;
      if (drawings.isNotEmpty) {
        updated = await _drawingRepo.upsertAll(drawings);
      }

      // Update last sync timestamp
      await _updateLastSyncDate();

      if (kDebugMode) {
        debugPrint('[DataSyncService] Sync complete: $updated updated, $skipped skipped');
      }

      return SyncResult(
        success: true,
        newDrawingsCount: updated,
        message: 'Successfully synced $updated drawing(s)${skipped > 0 ? ' ($skipped skipped)' : ''}',
        skippedCount: skipped,
      );
    } on ApiException catch (e) {
      if (kDebugMode) {
        debugPrint('[DataSyncService] API error: ${e.message}');
      }
      return SyncResult(
        success: false,
        newDrawingsCount: 0,
        message: 'API error: ${e.message}',
        error: e,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DataSyncService] Sync failed: $e');
      }
      return SyncResult(
        success: false,
        newDrawingsCount: 0,
        message: 'Sync failed: $e',
        error: e,
      );
    }
  }

  /// Transform API response data to Drawing model
  Drawing _transformApiDataToDrawing(Map<String, dynamic> data) {
    // API response format:
    // {
    //   "draw_date": "2025-12-04T00:00:00.000",
    //   "winning_numbers": "12 25 34 48 67",
    //   "powerball": "15",
    //   "multiplier": "2"
    // }

    final drawDateStr = data['draw_date'] as String;
    final drawDate = DateTime.parse(drawDateStr);

    // Parse winning numbers
    final winningNumbersStr = data['winning_numbers'] as String;
    final whiteBalls = winningNumbersStr
        .split(' ')
        .map((s) => int.parse(s.trim()))
        .toList()
      ..sort();

    final powerball = int.parse(data['powerball'] as String);
    final multiplier = data['multiplier'] != null
        ? int.parse(data['multiplier'] as String)
        : null;

    // Generate ID: drawing_YYYYMMDD
    final id = 'drawing_${drawDate.year}${drawDate.month.toString().padLeft(2, '0')}${drawDate.day.toString().padLeft(2, '0')}';

    return Drawing(
      id: id,
      drawDate: drawDate,
      whiteBalls: whiteBalls,
      powerball: powerball,
      multiplier: multiplier,
      jackpot: null, // Not provided by API
      createdAt: DateTime.now(),
      source: 'api',
    );
  }

  /// Get the last sync date from metadata box
  Future<DateTime?> _getLastSyncDate() async {
    final metadataBox = HiveService.getBox(HiveService.metadataBox);
    final timestamp = metadataBox.get('lastSyncAt');
    if (timestamp == null) return null;
    return DateTime.parse(timestamp as String);
  }

  /// Update the last sync date in metadata box
  Future<void> _updateLastSyncDate() async {
    final metadataBox = HiveService.getBox(HiveService.metadataBox);
    await metadataBox.put('lastSyncAt', DateTime.now().toIso8601String());
  }

  /// Get sync status information
  Future<SyncStatus> getSyncStatus() async {
    final lastSyncDate = await _getLastSyncDate();
    final totalDrawings = _drawingRepo.getCount();
    final latestDrawing = _drawingRepo.getLatestDrawing();

    return SyncStatus(
      lastSyncAt: lastSyncDate,
      totalDrawings: totalDrawings,
      latestDrawingDate: latestDrawing?.drawDate,
      isStale: lastSyncDate != null &&
          DateTime.now().difference(lastSyncDate).inDays > 7,
    );
  }

  /// Force a full refresh (fetch latest 100 drawings)
  Future<SyncResult> fullRefresh() async {
    try {
      if (kDebugMode) {
        debugPrint('[DataSyncService] Starting full refresh...');
      }

      final apiData = await _api.fetchLatestDrawings(100);
      final drawings = <Drawing>[];
      int skipped = 0;

      for (final data in apiData) {
        try {
          final drawing = _transformApiDataToDrawing(data);
          if (_validateDrawing(drawing)) {
            drawings.add(drawing);
          } else {
            skipped++;
          }
        } catch (e) {
          skipped++;
          if (kDebugMode) {
            debugPrint('[DataSyncService] Error transforming drawing: $e');
          }
        }
      }

      // Use upsert for efficient save
      final updated = await _drawingRepo.upsertAll(drawings);
      await _updateLastSyncDate();

      if (kDebugMode) {
        debugPrint('[DataSyncService] Full refresh complete: $updated updated');
      }

      return SyncResult(
        success: true,
        newDrawingsCount: updated,
        message: 'Full refresh completed: $updated drawing(s)',
        skippedCount: skipped,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DataSyncService] Full refresh failed: $e');
      }
      return SyncResult(
        success: false,
        newDrawingsCount: 0,
        message: 'Full refresh failed: $e',
        error: e,
      );
    }
  }

  /// Sync all historical data from API start date (2010) to present
  /// This is a long-running operation, use with progress callback
  Future<SyncResult> syncHistoricalData({
    Function(int processed, int total)? onProgress,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('[DataSyncService] Starting historical sync from ${apiStartDate.year}...');
      }

      final apiData = await _api.fetchDrawingsSince(apiStartDate);

      if (apiData.isEmpty) {
        return SyncResult(
          success: true,
          newDrawingsCount: 0,
          message: 'No historical data available',
        );
      }

      final drawings = <Drawing>[];
      int skipped = 0;
      int processed = 0;
      final total = apiData.length;

      for (final data in apiData) {
        try {
          final drawing = _transformApiDataToDrawing(data);
          if (_validateDrawing(drawing)) {
            drawings.add(drawing);
          } else {
            skipped++;
          }
        } catch (e) {
          skipped++;
          if (kDebugMode) {
            debugPrint('[DataSyncService] Error transforming drawing: $e');
          }
        }

        processed++;
        if (onProgress != null && processed % 50 == 0) {
          onProgress(processed, total);
        }
      }

      // Use upsert for efficient save
      final updated = await _drawingRepo.upsertAll(drawings);
      await _updateLastSyncDate();

      if (kDebugMode) {
        debugPrint('[DataSyncService] Historical sync complete: $updated updated, $skipped skipped');
      }

      return SyncResult(
        success: true,
        newDrawingsCount: updated,
        message: 'Historical sync completed: $updated drawing(s)',
        skippedCount: skipped,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DataSyncService] Historical sync failed: $e');
      }
      return SyncResult(
        success: false,
        newDrawingsCount: 0,
        message: 'Historical sync failed: $e',
        error: e,
      );
    }
  }

  /// Check API health before syncing
  Future<bool> checkApiHealth() async {
    try {
      return await _api.checkHealth();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DataSyncService] API health check failed: $e');
      }
      return false;
    }
  }

  /// Validate drawing data before storage
  bool _validateDrawing(Drawing drawing) {
    // Check white balls
    if (drawing.whiteBalls.length != 5) return false;
    if (drawing.whiteBalls.any((n) => n < 1 || n > 69)) return false;
    if (drawing.whiteBalls.toSet().length != 5) return false; // No duplicates

    // Check powerball
    if (drawing.powerball < 1 || drawing.powerball > 26) return false;

    // Check draw date is not in future
    if (drawing.drawDate.isAfter(DateTime.now())) return false;

    // Check draw date is not before API start
    if (drawing.drawDate.isBefore(apiStartDate)) return false;

    return true;
  }

  /// Find and sync missing drawings (gaps in data)
  Future<SyncResult> syncMissingDrawings() async {
    try {
      if (kDebugMode) {
        debugPrint('[DataSyncService] Checking for missing drawings...');
      }

      final gaps = _drawingRepo.findGaps();
      if (gaps.isEmpty) {
        return SyncResult(
          success: true,
          newDrawingsCount: 0,
          message: 'No gaps found in drawing data',
        );
      }

      if (kDebugMode) {
        debugPrint('[DataSyncService] Found ${gaps.length} potential gaps');
      }

      // Fetch drawings around gap dates
      int totalUpdated = 0;
      for (final gapDate in gaps) {
        try {
          final startDate = gapDate.subtract(const Duration(days: 7));
          final endDate = gapDate.add(const Duration(days: 7));

          final apiData = await _api.fetchDrawingsBetween(startDate, endDate);
          final drawings = <Drawing>[];

          for (final data in apiData) {
            try {
              final drawing = _transformApiDataToDrawing(data);
              if (_validateDrawing(drawing)) {
                drawings.add(drawing);
              }
            } catch (e) {
              // Skip invalid drawings
            }
          }

          if (drawings.isNotEmpty) {
            final updated = await _drawingRepo.upsertAll(drawings);
            totalUpdated += updated;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[DataSyncService] Error syncing gap at $gapDate: $e');
          }
        }
      }

      await _updateLastSyncDate();

      if (kDebugMode) {
        debugPrint('[DataSyncService] Gap sync complete: $totalUpdated drawings added');
      }

      return SyncResult(
        success: true,
        newDrawingsCount: totalUpdated,
        message: 'Synced $totalUpdated missing drawing(s)',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DataSyncService] Gap sync failed: $e');
      }
      return SyncResult(
        success: false,
        newDrawingsCount: 0,
        message: 'Gap sync failed: $e',
        error: e,
      );
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int newDrawingsCount;
  final String message;
  final int skippedCount;
  final Object? error;

  SyncResult({
    required this.success,
    required this.newDrawingsCount,
    required this.message,
    this.skippedCount = 0,
    this.error,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, new: $newDrawingsCount, skipped: $skippedCount, message: $message)';
  }
}

/// Current sync status
class SyncStatus {
  final DateTime? lastSyncAt;
  final int totalDrawings;
  final DateTime? latestDrawingDate;
  final bool isStale;

  SyncStatus({
    required this.lastSyncAt,
    required this.totalDrawings,
    required this.latestDrawingDate,
    required this.isStale,
  });

  String get statusMessage {
    if (lastSyncAt == null) return 'Never synced';
    if (isStale) return 'Data is stale (>7 days old)';
    return 'Last synced ${_formatDuration(DateTime.now().difference(lastSyncAt!))} ago';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) return '${duration.inDays}d';
    if (duration.inHours > 0) return '${duration.inHours}h';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '${duration.inSeconds}s';
  }
}
