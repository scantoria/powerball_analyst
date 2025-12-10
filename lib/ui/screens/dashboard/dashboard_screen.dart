import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/cycle_providers.dart';
import '../../../providers/drawing_providers.dart';
import '../../../providers/pick_providers.dart';
import '../../../providers/baseline_providers.dart';
import '../../../providers/analysis_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../models/pattern_shift.dart';
import '../../../services/sync/data_sync_service.dart';
import '../../widgets/baseline_progress.dart';
import '../../widgets/number_ball.dart';
import '../../../core/constants/app_colors.dart';
import '../../navigation/app_navigation.dart';

/// Dashboard screen - main overview
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCycle = ref.watch(currentCycleProvider);
    final isPhase1 = ref.watch(isPhase1Provider);
    final latestDrawing = ref.watch(latestDrawingProvider);
    final drawingCount = ref.watch(drawingCountProvider);
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final pickStats = ref.watch(pickStatsProvider);
    final activeShifts = ref.watch(activeShiftsProvider);
    final latestShift = ref.watch(latestShiftProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Powerball Analyst'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.goNamed(RouteNames.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(syncStatusProvider);
          ref.invalidate(latestDrawingProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Cycle Status
              if (currentCycle != null) ...[
                _buildCycleStatusCard(context, currentCycle, isPhase1),
                const SizedBox(height: 16),
              ] else ...[
                _buildNoCycleCard(context),
                const SizedBox(height: 16),
              ],

              // Sync Status Card
              syncStatusAsync.when(
                data: (syncStatus) => _buildSyncStatusCard(context, ref, syncStatus),
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => _buildErrorCard(context, 'Sync Status Error', error.toString()),
              ),
              const SizedBox(height: 16),

              // Pattern Shift Alerts Card
              if (activeShifts.isNotEmpty) ...[
                _buildPatternShiftCard(context, ref, activeShifts, latestShift),
                const SizedBox(height: 16),
              ],

              // Latest Drawing Card
              if (latestDrawing != null) ...[
                _buildLatestDrawingCard(context, latestDrawing),
                const SizedBox(height: 16),
              ],

              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Drawings',
                      drawingCount.toString(),
                      Icons.casino,
                      AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      'Picks',
                      pickStats['totalPicks'].toString(),
                      Icons.looks_one,
                      AppColors.accentOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Actions
              _buildQuickActionsCard(context, ref, currentCycle),
              const SizedBox(height: 16),

              // Pick Statistics (if any picks exist)
              if (pickStats['totalPicks'] > 0) ...[
                _buildPickStatsCard(context, pickStats),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCycleStatusCard(BuildContext context, dynamic cycle, bool isPhase1) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPhase1 ? Icons.hourglass_empty : Icons.analytics,
                  color: isPhase1 ? AppColors.accentOrange : AppColors.successGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  isPhase1 ? 'Phase 1: Building Baseline' : 'Phase 2: Active Analysis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isPhase1) ...[
              BaselineProgress(
                currentDrawings: cycle.drawingCount,
                message: 'Full analysis available after 20 drawings',
              ),
            ] else ...[
              Text(
                '${cycle.drawingCount} drawings collected',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Started ${_formatDate(cycle.startDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoCycleCard(BuildContext context) {
    return Card(
      color: AppColors.warningYellow.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.warningYellow),
                const SizedBox(width: 8),
                Text(
                  'No Active Cycle',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Create a cycle to start analyzing Powerball patterns',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context, WidgetRef ref, SyncStatus syncStatus) {
    final isStale = syncStatus.isStale;
    final lastSync = syncStatus.lastSyncAt;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isStale ? Icons.sync_problem : Icons.check_circle,
                      color: isStale ? AppColors.errorRed : AppColors.successGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Data Sync',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Sync Now'),
                  onPressed: () => _syncData(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              lastSync != null
                  ? 'Last synced: ${_formatDateTime(lastSync)}'
                  : 'Never synced',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (syncStatus.latestDrawingDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Latest drawing: ${_formatDate(syncStatus.latestDrawingDate!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLatestDrawingCard(BuildContext context, dynamic drawing) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest Drawing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  _formatDate(drawing.drawDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...drawing.whiteBalls.map((num) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: NumberBall(
                        number: num,
                        isPowerball: false,
                        size: 40,
                      ),
                    )),
                const SizedBox(width: 8),
                NumberBall(
                  number: drawing.powerball,
                  isPowerball: true,
                  size: 40,
                ),
              ],
            ),
            if (drawing.multiplier != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  label: Text('${drawing.multiplier}X Power Play'),
                  avatar: const Icon(Icons.bolt, size: 16),
                  backgroundColor: AppColors.accentOrange.withOpacity(0.1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, WidgetRef ref, dynamic currentCycle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Create Pick'),
                  onPressed: currentCycle != null
                      ? () => context.goNamed(RouteNames.picker)
                      : null,
                ),
                ActionChip(
                  avatar: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('View Analysis'),
                  onPressed: currentCycle != null
                      ? () => context.goNamed(RouteNames.analysis)
                      : null,
                ),
                ActionChip(
                  avatar: const Icon(Icons.history, size: 18),
                  label: const Text('History'),
                  onPressed: () => context.goNamed(RouteNames.history),
                ),
                ActionChip(
                  avatar: const Icon(Icons.timeline, size: 18),
                  label: const Text('Cycles'),
                  onPressed: () => context.goNamed(RouteNames.cycles),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickStatsCard(BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildStatRow(context, 'Total Picks', stats['totalPicks'].toString()),
            const SizedBox(height: 8),
            _buildStatRow(context, 'Evaluated', stats['evaluatedPicks'].toString()),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'Average Matches',
              stats['avgMatches'].toStringAsFixed(2),
            ),
            const SizedBox(height: 8),
            _buildStatRow(context, 'Best Match', '${stats['bestMatch']} balls'),
            const SizedBox(height: 8),
            _buildStatRow(context, 'Powerball Hits', stats['powerballHits'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, String title, String message) {
    return Card(
      color: AppColors.errorRed.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.errorRed),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.errorRed,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternShiftCard(
    BuildContext context,
    WidgetRef ref,
    List<PatternShift> shifts,
    PatternShift? latestShift,
  ) {
    return Card(
      color: _getShiftCardColor(latestShift?.severity),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: _getShiftIconColor(latestShift?.severity),
                ),
                const SizedBox(width: 8),
                Text(
                  'Pattern Shift Alert',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (shifts.length > 1)
                  Chip(
                    label: Text('${shifts.length}'),
                    backgroundColor: AppColors.errorRed.withOpacity(0.2),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            if (latestShift != null) ...[
              const SizedBox(height: 12),
              Text(
                _getShiftDescription(latestShift.triggerType),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Severity: ${latestShift.severity.name.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getShiftIconColor(latestShift.severity),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _dismissShift(ref, latestShift.id),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getShiftCardColor(ShiftSeverity? severity) {
    if (severity == null) return AppColors.warningYellow.withOpacity(0.1);
    switch (severity) {
      case ShiftSeverity.high:
        return AppColors.errorRed.withOpacity(0.1);
      case ShiftSeverity.medium:
        return AppColors.warningYellow.withOpacity(0.1);
      case ShiftSeverity.low:
        return Colors.blue.withOpacity(0.1);
    }
  }

  Color _getShiftIconColor(ShiftSeverity? severity) {
    if (severity == null) return AppColors.warningYellow;
    switch (severity) {
      case ShiftSeverity.high:
        return AppColors.errorRed;
      case ShiftSeverity.medium:
        return AppColors.warningYellow;
      case ShiftSeverity.low:
        return Colors.blue;
    }
  }

  String _getShiftDescription(ShiftTrigger trigger) {
    switch (trigger) {
      case ShiftTrigger.longTermDrift:
        return 'Long-term drift detected: Hot numbers from B₀ now below average';
      case ShiftTrigger.shortTermSurge:
        return 'Short-term surge: Multiple numbers jumped significantly';
      case ShiftTrigger.baselineDivergence:
        return 'Baseline divergence: B₀ and Bₙ patterns differ significantly';
      case ShiftTrigger.correlationBreakdown:
        return 'Correlation breakdown: Top pairs no longer co-occurring';
      case ShiftTrigger.newDominance:
        return 'New dominance: Previously uncommon numbers now top performers';
    }
  }

  Future<void> _dismissShift(WidgetRef ref, String shiftId) async {
    final repo = ref.read(patternShiftRepositoryProvider);
    await repo.dismiss(shiftId);
    ref.invalidate(patternShiftsProvider);
  }

  void _syncData(BuildContext context, WidgetRef ref) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Syncing data...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Trigger sync
      ref.invalidate(syncStatusProvider);
      ref.invalidate(latestDrawingProvider);
      ref.invalidate(drawingCountProvider);

      // Wait a moment for sync to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Trigger orchestration after sync
      final orchestrator = ref.read(cycleOrchestrationServiceProvider);
      final drawingRepo = ref.read(drawingRepositoryProvider);

      // Get recently added drawings (last 100)
      final newDrawings = drawingRepo.getLatest(100);

      // Process new drawings through orchestration
      await orchestrator.onDrawingsAdded(newDrawings);

      // Invalidate baseline providers to refresh UI
      ref.invalidate(activeBaselineProvider);
      ref.invalidate(initialBaselineProvider);
      ref.invalidate(rollingBaselineProvider);
      ref.invalidate(patternShiftsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync complete!'),
            backgroundColor: AppColors.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return _formatDate(dateTime);
  }
}
