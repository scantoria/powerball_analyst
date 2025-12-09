import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/pick_providers.dart';
import '../../../providers/drawing_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/number_ball.dart';

/// History screen - pick tracking and results
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _pickFilter = 'all'; // all, evaluated, unevaluated
  String _drawingFilter = 'all'; // all, recent, thisYear

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.casino), text: 'Drawings'),
            Tab(icon: Icon(Icons.looks_one), text: 'My Picks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDrawingsTab(),
          _buildPicksTab(),
        ],
      ),
    );
  }

  Widget _buildDrawingsTab() {
    final drawings = ref.watch(drawingsProvider);
    final filteredDrawings = _filterDrawings(drawings);

    return Column(
      children: [
        _buildDrawingFilterBar(),
        Expanded(
          child: filteredDrawings.isEmpty
              ? _buildEmptyState('No Drawings', 'Sync data to see drawing history')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDrawings.length,
                  itemBuilder: (context, index) {
                    final drawing = filteredDrawings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(drawing.drawDate),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                        size: 36,
                                      ),
                                    )),
                                const SizedBox(width: 8),
                                NumberBall(
                                  number: drawing.powerball,
                                  isPowerball: true,
                                  size: 36,
                                ),
                              ],
                            ),
                            if (drawing.multiplier != null) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: Chip(
                                  label: Text('${drawing.multiplier}X Power Play'),
                                  backgroundColor: AppColors.accentOrange.withOpacity(0.2),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPicksTab() {
    final picks = ref.watch(pickHistoryProvider);
    final filteredPicks = _filterPicks(picks);

    return Column(
      children: [
        _buildPickFilterBar(),
        Expanded(
          child: filteredPicks.isEmpty
              ? _buildEmptyState('No Picks', 'Create picks to track your selections')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPicks.length,
                  itemBuilder: (context, index) {
                    final pick = filteredPicks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Target: ${_formatDate(pick.targetDrawDate)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                _buildPickStatusChip(pick),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (pick.isAutoPick)
                                  Chip(
                                    label: const Text('Auto', style: TextStyle(fontSize: 11)),
                                    backgroundColor: AppColors.accentOrange.withOpacity(0.2),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                if (pick.isPreliminary) ...[
                                  const SizedBox(width: 4),
                                  Chip(
                                    label: const Text('Prelim', style: TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.blue.withOpacity(0.2),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...pick.whiteBalls.map((num) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: NumberBall(
                                        number: num,
                                        isPowerball: false,
                                        size: 36,
                                      ),
                                    )),
                                const SizedBox(width: 8),
                                NumberBall(
                                  number: pick.powerball,
                                  isPowerball: true,
                                  size: 36,
                                ),
                              ],
                            ),
                            if (pick.evaluatedAt != null) ...[
                              const SizedBox(height: 12),
                              _buildPickResults(pick),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDrawingFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Filter: '),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('All'),
            selected: _drawingFilter == 'all',
            onSelected: (_) => setState(() => _drawingFilter = 'all'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Recent'),
            selected: _drawingFilter == 'recent',
            onSelected: (_) => setState(() => _drawingFilter = 'recent'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('This Year'),
            selected: _drawingFilter == 'thisYear',
            onSelected: (_) => setState(() => _drawingFilter = 'thisYear'),
          ),
        ],
      ),
    );
  }

  Widget _buildPickFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Filter: '),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('All'),
            selected: _pickFilter == 'all',
            onSelected: (_) => setState(() => _pickFilter = 'all'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Evaluated'),
            selected: _pickFilter == 'evaluated',
            onSelected: (_) => setState(() => _pickFilter = 'evaluated'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Pending'),
            selected: _pickFilter == 'unevaluated',
            onSelected: (_) => setState(() => _pickFilter = 'unevaluated'),
          ),
        ],
      ),
    );
  }

  Widget _buildPickStatusChip(dynamic pick) {
    if (pick.evaluatedAt == null) {
      return Chip(
        label: const Text('Pending', style: TextStyle(fontSize: 11)),
        backgroundColor: Colors.grey.withOpacity(0.2),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }

    final hasWin = (pick.matchCount ?? 0) > 0 || (pick.powerballMatch == true);
    return Chip(
      label: Text(
        hasWin ? 'Winner!' : 'No Match',
        style: const TextStyle(fontSize: 11),
      ),
      backgroundColor: hasWin
          ? AppColors.successGreen.withOpacity(0.2)
          : Colors.grey.withOpacity(0.2),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildPickResults(dynamic pick) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('White Ball Matches: ${pick.matchCount ?? 0}'),
              Text('Powerball Match: ${pick.powerballMatch == true ? "Yes" : "No"}'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Prize Tier: ${_getPrizeTier(pick)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

  List<dynamic> _filterDrawings(List<dynamic> drawings) {
    switch (_drawingFilter) {
      case 'recent':
        return drawings.take(20).toList();
      case 'thisYear':
        final currentYear = DateTime.now().year;
        return drawings.where((d) => d.drawDate.year == currentYear).toList();
      default:
        return drawings;
    }
  }

  List<dynamic> _filterPicks(List<dynamic> picks) {
    switch (_pickFilter) {
      case 'evaluated':
        return picks.where((p) => p.evaluatedAt != null).toList();
      case 'unevaluated':
        return picks.where((p) => p.evaluatedAt == null).toList();
      default:
        return picks;
    }
  }

  String _getPrizeTier(dynamic pick) {
    if (pick.matchCount == null) return 'Not Evaluated';

    final matches = pick.matchCount!;
    final pbMatch = pick.powerballMatch == true;

    if (matches == 5 && pbMatch) return 'Jackpot';
    if (matches == 5 && !pbMatch) return 'Match 5 (\$1M)';
    if (matches == 4 && pbMatch) return 'Match 4 + PB (\$50K)';
    if (matches == 4 && !pbMatch) return 'Match 4 (\$100)';
    if (matches == 3 && pbMatch) return 'Match 3 + PB (\$100)';
    if (matches == 3 && !pbMatch) return 'Match 3 (\$7)';
    if (matches == 2 && pbMatch) return 'Match 2 + PB (\$7)';
    if (matches == 1 && pbMatch) return 'Match 1 + PB (\$4)';
    if (matches == 0 && pbMatch) return 'PB Only (\$4)';

    return 'No Win';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
