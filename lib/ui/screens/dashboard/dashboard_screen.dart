import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/cycle_providers.dart';
import '../../../providers/drawing_providers.dart';
import '../../widgets/baseline_progress.dart';

/// Dashboard screen - main overview
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCycle = ref.watch(currentCycleProvider);
    final isPhase1 = ref.watch(isPhase1Provider);
    final latestDrawing = ref.watch(latestDrawingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Powerball Analyst'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baseline Status
            if (currentCycle != null) ...[
              if (isPhase1)
                BaselineProgress(
                  currentDrawings: currentCycle.drawingCount,
                  message: 'Full analysis available after 20 drawings',
                )
              else
                BaselineStatusBadge(
                  isActive: true,
                  drawingCount: currentCycle.drawingCount,
                ),
              const SizedBox(height: 24),
            ],

            // Latest Drawing
            if (latestDrawing != null) ...[
              Text(
                'Latest Drawing',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text(
                    'Draw Date: ${latestDrawing.drawDate.toString().split(' ')[0]}',
                  ),
                  subtitle: Text(
                    'White Balls: ${latestDrawing.whiteBalls.join(', ')}\n'
                    'Powerball: ${latestDrawing.powerball}',
                  ),
                  isThreeLine: true,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Placeholder sections
            _buildPlaceholderSection(
              context,
              'Hot Numbers',
              'Top performing numbers will appear here',
            ),
            const SizedBox(height: 16),
            _buildPlaceholderSection(
              context,
              'Recent Trends',
              'Pattern analysis will appear here',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderSection(
    BuildContext context,
    String title,
    String description,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
