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
class DataSyncService {
  final NYLotteryApi _api;
  final DrawingRepository _drawingRepo;
  final _uuid = const Uuid();

  DataSyncService({
    NYLotteryApi? api,
    DrawingRepository? drawingRepo,
  })  : _api = api ?? NYLotteryApi(),
        _drawingRepo = drawingRepo ?? DrawingRepository();

  /// Sync new drawings from the API
  /// Returns the number of new drawings added
  Future<SyncResult> syncDrawings() async {
    try {
      final lastSyncDate = await _getLastSyncDate();
      final apiData = lastSyncDate != null
          ? await _api.fetchDrawingsSince(lastSyncDate)
          : await _api.fetchLatestDrawings(100); // First sync: get latest 100

      if (apiData.isEmpty) {
        return SyncResult(
          success: true,
          newDrawingsCount: 0,
          message: 'No new drawings to sync',
        );
      }

      // Transform API data to Drawing models
      final drawings = <Drawing>[];
      for (final data in apiData) {
        try {
          final drawing = _transformApiDataToDrawing(data);
          // Only add if not already in storage
          if (!_drawingRepo.exists(drawing.id)) {
            drawings.add(drawing);
          }
        } catch (e) {
          // Log error but continue with other drawings
          print('Error transforming drawing: $e');
        }
      }

      // Save to Hive
      if (drawings.isNotEmpty) {
        await _drawingRepo.saveAll(drawings);
      }

      // Update last sync timestamp
      await _updateLastSyncDate();

      return SyncResult(
        success: true,
        newDrawingsCount: drawings.length,
        message: 'Successfully synced ${drawings.length} new drawing(s)',
      );
    } on ApiException catch (e) {
      return SyncResult(
        success: false,
        newDrawingsCount: 0,
        message: 'API error: ${e.message}',
        error: e,
      );
    } catch (e) {
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
      final apiData = await _api.fetchLatestDrawings(100);
      final drawings = <Drawing>[];

      for (final data in apiData) {
        try {
          final drawing = _transformApiDataToDrawing(data);
          drawings.add(drawing);
        } catch (e) {
          print('Error transforming drawing: $e');
        }
      }

      // Save all (will overwrite existing)
      await _drawingRepo.saveAll(drawings);
      await _updateLastSyncDate();

      return SyncResult(
        success: true,
        newDrawingsCount: drawings.length,
        message: 'Full refresh completed: ${drawings.length} drawings',
      );
    } catch (e) {
      return SyncResult(
        success: false,
        newDrawingsCount: 0,
        message: 'Full refresh failed: $e',
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
  final Object? error;

  SyncResult({
    required this.success,
    required this.newDrawingsCount,
    required this.message,
    this.error,
  });
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
