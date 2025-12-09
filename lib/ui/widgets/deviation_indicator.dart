import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/number_stats.dart';

/// Widget for displaying deviation/trend indicators
/// Shows simple mode (icons) or advanced mode (numeric scores)
class DeviationIndicator extends StatelessWidget {
  final Classification classification;
  final Trend trend;
  final double? deviation;
  final bool showAdvanced;

  const DeviationIndicator({
    super.key,
    required this.classification,
    required this.trend,
    this.deviation,
    this.showAdvanced = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showAdvanced && deviation != null) {
      return _buildAdvancedMode(context);
    }
    return _buildSimpleMode(context);
  }

  Widget _buildSimpleMode(BuildContext context) {
    final icon = _getTrendIcon(trend);
    final color = _getClassificationColor(classification);
    final label = _getClassificationLabel(classification);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedMode(BuildContext context) {
    final color = _getClassificationColor(classification);
    final sign = deviation! >= 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$sign${deviation!.toStringAsFixed(2)}σ',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  IconData _getTrendIcon(Trend trend) {
    switch (trend) {
      case Trend.rising:
        return Icons.trending_up;
      case Trend.falling:
        return Icons.trending_down;
      case Trend.stable:
        return Icons.trending_flat;
    }
  }

  Color _getClassificationColor(Classification classification) {
    switch (classification) {
      case Classification.hot:
        return AppColors.hotRising;
      case Classification.warm:
        return AppColors.warming;
      case Classification.stable:
        return AppColors.stable;
      case Classification.cool:
        return AppColors.cooling;
      case Classification.cold:
        return AppColors.coldFalling;
    }
  }

  String _getClassificationLabel(Classification classification) {
    switch (classification) {
      case Classification.hot:
        return 'Hot Rising';
      case Classification.warm:
        return 'Warming';
      case Classification.stable:
        return 'Stable';
      case Classification.cool:
        return 'Cooling';
      case Classification.cold:
        return 'Cold Falling';
    }
  }
}

/// Simple trend arrow indicator
class TrendArrow extends StatelessWidget {
  final Trend trend;
  final double size;

  const TrendArrow({
    super.key,
    required this.trend,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (trend) {
      case Trend.rising:
        icon = Icons.arrow_upward;
        color = AppColors.hotRising;
        break;
      case Trend.falling:
        icon = Icons.arrow_downward;
        color = AppColors.coldFalling;
        break;
      case Trend.stable:
        icon = Icons.remove;
        color = AppColors.stable;
        break;
    }

    return Icon(icon, size: size, color: color);
  }
}
