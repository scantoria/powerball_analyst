import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/baseline_providers.dart';
import '../../../providers/cycle_providers.dart';
import '../../../models/baseline.dart' as app_models;
import '../../../core/constants/app_colors.dart';
import '../../widgets/number_ball.dart';

/// Baseline Comparison screen - compare B₀ and Bₙ baselines
class BaselineComparisonScreen extends ConsumerWidget {
  const BaselineComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCycle = ref.watch(currentCycleProvider);
    final b0 = ref.watch(initialBaselineProvider);
    final bn = ref.watch(rollingBaselineProvider);
    final overlapScore = ref.watch(overlapScoreProvider);

    if (currentCycle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Baseline Comparison')),
        body: _buildNoCycleState(context),
      );
    }

    if (b0 == null || bn == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Baseline Comparison')),
        body: _buildNoBaselinesState(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baseline Comparison'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overlap Score Card
            if (overlapScore != null) ...[
              Card(
                color: _getOverlapColor(overlapScore).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Overlap Score',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${overlapScore.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getOverlapColor(overlapScore),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getOverlapMessage(overlapScore),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // B₀ Section
            Text(
              'Initial Baseline (B₀)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildBaselineCard(context, b0),
            const SizedBox(height: 24),

            // Bₙ Section
            Text(
              'Rolling Baseline (Bₙ)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildBaselineCard(context, bn),
            const SizedBox(height: 24),

            // Comparison Section
            Text(
              'Hot Numbers Comparison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildComparisonCard(context, b0, bn),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCycleState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 80, color: AppColors.warningYellow),
            const SizedBox(height: 16),
            Text('No Active Cycle', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create a cycle to compare baselines',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBaselinesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_outlined, size: 80, color: AppColors.accentOrange),
            const SizedBox(height: 16),
            Text('Baselines Not Available', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Both B₀ and Bₙ baselines are required for comparison',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaselineCard(BuildContext context, app_models.Baseline baseline) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${baseline.drawingCount} drawings • ${_formatDateRange(baseline.drawingRange)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hot Numbers',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: baseline.hotWhiteballs
                  .map((num) => NumberBall(number: num, isPowerball: false, size: 36))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildStatRow(context, 'Mean', baseline.statistics.mean.toStringAsFixed(2)),
            _buildStatRow(context, 'Std Dev', baseline.statistics.stdDev.toStringAsFixed(2)),
            _buildStatRow(context, 'Min/Max', '${baseline.statistics.min}/${baseline.statistics.max}'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context, app_models.Baseline b0, app_models.Baseline bn) {
    final b0Set = Set<int>.from(b0.hotWhiteballs);
    final bnSet = Set<int>.from(bn.hotWhiteballs);
    final common = b0Set.intersection(bnSet).toList()..sort();
    final onlyB0 = b0Set.difference(bnSet).toList()..sort();
    final onlyBn = bnSet.difference(b0Set).toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (common.isNotEmpty) ...[
              Text(
                'Common Hot Numbers (${common.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.successGreen,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: common
                    .map((num) => NumberBall(number: num, isPowerball: false, size: 36))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (onlyB0.isNotEmpty) ...[
              Text(
                'Only in B₀ (${onlyB0.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: onlyB0
                    .map((num) => NumberBall(number: num, isPowerball: false, size: 36))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (onlyBn.isNotEmpty) ...[
              Text(
                'Only in Bₙ (${onlyBn.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: onlyBn
                    .map((num) => NumberBall(number: num, isPowerball: false, size: 36))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Color _getOverlapColor(double score) {
    if (score >= 70) return AppColors.successGreen;
    if (score >= 50) return AppColors.warningYellow;
    return AppColors.errorRed;
  }

  String _getOverlapMessage(double score) {
    if (score >= 70) return 'High consistency between baselines';
    if (score >= 50) return 'Moderate divergence detected';
    return 'Significant divergence - pattern shift likely';
  }

  String _formatDateRange(app_models.DateRange range) {
    return '${_formatDate(range.startDate)} - ${_formatDate(range.endDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
