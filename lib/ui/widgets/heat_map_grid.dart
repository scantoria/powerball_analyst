import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Simple heat map grid for displaying number frequencies
class HeatMapGrid extends StatelessWidget {
  final Map<int, int> frequencies;
  final int maxNumber;
  final Function(int)? onNumberTap;

  const HeatMapGrid({
    super.key,
    required this.frequencies,
    this.maxNumber = 69,
    this.onNumberTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxFreq = frequencies.values.isEmpty
        ? 1
        : frequencies.values.reduce((a, b) => a > b ? a : b);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: maxNumber,
      itemBuilder: (context, index) {
        final number = index + 1;
        final frequency = frequencies[number] ?? 0;
        final intensity = maxFreq > 0 ? frequency / maxFreq : 0.0;

        return GestureDetector(
          onTap: onNumberTap != null ? () => onNumberTap!(number) : null,
          child: Container(
            decoration: BoxDecoration(
              color: _getHeatColor(intensity),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.divider,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: intensity > 0.5 ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getHeatColor(double intensity) {
    if (intensity == 0) return Colors.grey.shade200;
    if (intensity < 0.2) return AppColors.coldBlue.withOpacity(0.3);
    if (intensity < 0.4) return AppColors.stable.withOpacity(0.4);
    if (intensity < 0.6) return AppColors.warming.withOpacity(0.5);
    if (intensity < 0.8) return AppColors.accentOrange;
    return AppColors.hotRising;
  }
}
