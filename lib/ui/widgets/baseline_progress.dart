import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/powerball_constants.dart';

/// Widget for displaying baseline collection progress (Phase 1)
class BaselineProgress extends StatelessWidget {
  final int currentDrawings;
  final int totalRequired;
  final String? message;

  const BaselineProgress({
    super.key,
    required this.currentDrawings,
    this.totalRequired = PowerballConstants.baselineDrawingCount,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentDrawings / totalRequired;
    final drawingsRemaining = totalRequired - currentDrawings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  color: AppColors.accentOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Building Baseline...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryBlue,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentDrawings / $totalRequired drawings',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '$drawingsRemaining more needed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact baseline status indicator
class BaselineStatusBadge extends StatelessWidget {
  final bool isActive;
  final int? drawingCount;
  final double? overlapScore;

  const BaselineStatusBadge({
    super.key,
    required this.isActive,
    this.drawingCount,
    this.overlapScore,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return Chip(
        avatar: const Icon(Icons.hourglass_empty, size: 16),
        label: Text('Collecting: ${drawingCount ?? 0}/20'),
        backgroundColor: AppColors.accentOrange.withOpacity(0.1),
      );
    }

    return Chip(
      avatar: const Icon(Icons.check_circle, size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Baseline Active'),
          if (overlapScore != null) ...[
            const SizedBox(width: 8),
            Text(
              '${(overlapScore! * 100).toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
      backgroundColor: AppColors.successGreen.withOpacity(0.1),
    );
  }
}
