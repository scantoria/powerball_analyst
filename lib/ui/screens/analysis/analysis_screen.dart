import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/baseline_providers.dart';
import '../../../providers/cycle_providers.dart';
import '../../../models/baseline.dart' as app_models;
import '../../../core/constants/app_colors.dart';
import '../../widgets/heat_map_grid.dart';
import '../../widgets/number_ball.dart';

/// Analysis screen - frequency, patterns, deviation display
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCycle = ref.watch(currentCycleProvider);
    final activeBaseline = ref.watch(activeBaselineProvider);
    final isPhase1 = ref.watch(isPhase1Provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.grid_on), text: 'Heat Map'),
            Tab(icon: Icon(Icons.trending_up), text: 'Hot/Cold'),
            Tab(icon: Icon(Icons.analytics), text: 'Statistics'),
          ],
        ),
      ),
      body: currentCycle == null
          ? _buildNoCycleState()
          : activeBaseline == null
              ? _buildNoBaselineState(isPhase1)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHeatMapTab(activeBaseline),
                    _buildHotColdTab(activeBaseline),
                    _buildStatisticsTab(activeBaseline),
                  ],
                ),
    );
  }

  Widget _buildNoCycleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              size: 80,
              color: AppColors.warningYellow,
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Cycle',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a cycle to start analyzing patterns',
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

  Widget _buildNoBaselineState(bool isPhase1) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPhase1 ? Icons.hourglass_empty : Icons.analytics_outlined,
              size: 80,
              color: AppColors.accentOrange,
            ),
            const SizedBox(height: 16),
            Text(
              isPhase1 ? 'Building Baseline...' : 'No Baseline Available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              isPhase1
                  ? 'Analysis will be available after 20 drawings are collected'
                  : 'Baseline data is not yet available',
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

  Widget _buildHeatMapTab(app_models.Baseline baseline) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baseline Info Card
          _buildBaselineInfoCard(baseline),
          const SizedBox(height: 24),

          // White Balls Heat Map
          Text(
            'White Balls (1-69)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HeatMapGrid(
                frequencies: baseline.whiteballFreq,
                maxNumber: 69,
                onNumberTap: (number) => _showNumberDetails(number, baseline, true),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Powerball Heat Map
          Text(
            'Powerballs (1-26)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: HeatMapGrid(
                frequencies: baseline.powerballFreq,
                maxNumber: 26,
                onNumberTap: (number) => _showNumberDetails(number, baseline, false),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          _buildHeatMapLegend(),
        ],
      ),
    );
  }

  Widget _buildHotColdTab(app_models.Baseline baseline) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hot White Balls
          Text(
            'Hot White Balls (Top 20%)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: baseline.hotWhiteballs.isEmpty
                  ? const Text('No hot numbers yet')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: baseline.hotWhiteballs
                          .map((num) => NumberBall(
                                number: num,
                                isPowerball: false,
                                size: 40,
                              ))
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Cold White Balls
          Text(
            'Cold White Balls (Bottom 20%)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: baseline.coldWhiteballs.isEmpty
                  ? const Text('No cold numbers yet')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: baseline.coldWhiteballs
                          .map((num) => NumberBall(
                                number: num,
                                isPowerball: false,
                                size: 40,
                              ))
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Never Drawn White Balls
          if (baseline.neverDrawnWB.isNotEmpty) ...[
            Text(
              'Never Drawn White Balls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: baseline.neverDrawnWB
                      .map((num) => NumberBall(
                            number: num,
                            isPowerball: false,
                            size: 40,
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Hot Powerballs
          Text(
            'Hot Powerballs (Top 20%)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: baseline.hotPowerballs.isEmpty
                  ? const Text('No hot powerballs yet')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: baseline.hotPowerballs
                          .map((num) => NumberBall(
                                number: num,
                                isPowerball: true,
                                size: 40,
                              ))
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Never Drawn Powerballs
          if (baseline.neverDrawnPB.isNotEmpty) ...[
            Text(
              'Never Drawn Powerballs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: baseline.neverDrawnPB
                      .map((num) => NumberBall(
                            number: num,
                            isPowerball: true,
                            size: 40,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(app_models.Baseline baseline) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baseline Metadata
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Baseline Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Type', _getBaselineTypeLabel(baseline.type)),
                  _buildStatRow('Drawings Analyzed', baseline.drawingCount.toString()),
                  _buildStatRow(
                    'Date Range',
                    '${_formatDate(baseline.drawingRange.startDate)} - ${_formatDate(baseline.drawingRange.endDate)}',
                  ),
                  _buildStatRow(
                    'Created',
                    _formatDateTime(baseline.createdAt),
                  ),
                  if (baseline.smoothingFactor != null)
                    _buildStatRow(
                      'Smoothing Factor',
                      baseline.smoothingFactor!.toStringAsFixed(2),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Statistical Metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistical Metrics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Mean Frequency', baseline.statistics.mean.toStringAsFixed(2)),
                  _buildStatRow('Standard Deviation', baseline.statistics.stdDev.toStringAsFixed(2)),
                  _buildStatRow('Median Frequency', baseline.statistics.median.toStringAsFixed(2)),
                  _buildStatRow('Min Frequency', baseline.statistics.min.toString()),
                  _buildStatRow('Max Frequency', baseline.statistics.max.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Frequency Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequency Distribution',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow('Hot Numbers', baseline.hotWhiteballs.length.toString()),
                  _buildStatRow('Cold Numbers', baseline.coldWhiteballs.length.toString()),
                  _buildStatRow('Never Drawn (WB)', baseline.neverDrawnWB.length.toString()),
                  _buildStatRow('Hot Powerballs', baseline.hotPowerballs.length.toString()),
                  _buildStatRow('Never Drawn (PB)', baseline.neverDrawnPB.length.toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineInfoCard(app_models.Baseline baseline) {
    return Card(
      color: AppColors.primaryBlue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getBaselineIcon(baseline.type),
              color: AppColors.primaryBlue,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getBaselineTypeLabel(baseline.type),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${baseline.drawingCount} drawings • ${_formatDate(baseline.drawingRange.startDate)} - ${_formatDate(baseline.drawingRange.endDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatMapLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heat Map Legend',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Cold', AppColors.coldBlue),
                _buildLegendItem('Stable', AppColors.stable),
                _buildLegendItem('Warm', AppColors.warming),
                _buildLegendItem('Hot', AppColors.hotRising),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
      ),
    );
  }

  void _showNumberDetails(int number, app_models.Baseline baseline, bool isWhiteBall) {
    final frequency = isWhiteBall
        ? baseline.whiteballFreq[number] ?? 0
        : baseline.powerballFreq[number] ?? 0;
    final isHot = isWhiteBall
        ? baseline.hotWhiteballs.contains(number)
        : baseline.hotPowerballs.contains(number);
    final isCold = isWhiteBall && baseline.coldWhiteballs.contains(number);
    final neverDrawn = isWhiteBall
        ? baseline.neverDrawnWB.contains(number)
        : baseline.neverDrawnPB.contains(number);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Number $number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Frequency: $frequency times'),
            const SizedBox(height: 8),
            if (isHot)
              Chip(
                label: const Text('Hot'),
                backgroundColor: AppColors.hotRising.withOpacity(0.3),
              ),
            if (isCold)
              Chip(
                label: const Text('Cold'),
                backgroundColor: AppColors.coldBlue.withOpacity(0.3),
              ),
            if (neverDrawn)
              Chip(
                label: const Text('Never Drawn'),
                backgroundColor: Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getBaselineTypeLabel(app_models.BaselineType type) {
    switch (type) {
      case app_models.BaselineType.initial:
        return 'Initial Baseline (B₀)';
      case app_models.BaselineType.rolling:
        return 'Rolling Baseline (Bₙ)';
      case app_models.BaselineType.preliminary:
        return 'Preliminary Baseline (Bₚ)';
    }
  }

  IconData _getBaselineIcon(app_models.BaselineType type) {
    switch (type) {
      case app_models.BaselineType.initial:
        return Icons.lock;
      case app_models.BaselineType.rolling:
        return Icons.autorenew;
      case app_models.BaselineType.preliminary:
        return Icons.hourglass_empty;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
